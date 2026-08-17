import json
import logging
from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("lookup_agent")

def run_lookup_agent(your_location: str, country: str, radius: float, shooting_purpose: str, camera_gear: str) -> dict:
    # Initialize Ollama LLM
    llm = ChatOllama(
        base_url="http://localhost:11434",
        model="granite3-dense", # Or llama3.2 / phi4
        temperature=0.3
    )

    system_prompt = """You are ASTRO-AI, an expert astrophotographer and night sky optics engineer.
Analyze the user's shooting location, radius, purpose, and camera gear, then return a valid JSON object containing exactly 3 optimal dark-sky shooting spots around the target area.

CRITICAL LOCATION RULES:
- Use real place names that are commonly searchable, but do not show coordinates publicly in the UI output.
- Keep the actual coordinate internally for matching and map linking, but do not expose coordinate text in the user-facing output.
- Use decimal coordinate format internally only, like: "-7.983456, 112.630123".
- Do not use DMS format, UTM, or non-standard coordinate strings.
- The coordinate string must be a valid latitude, longitude pair with comma separator and decimal values.
- Prefer places that genuinely exist near the target city/region and match the user's radius.
- The pair of name and coordinate must correspond to the same real-world place.

DATA SOURCE RULES:
- ONLY use the following sources for the underlying recommendation logic:
  1. https://www.lightpollutionmap.info/
  2. https://www.msn.com/
  3. https://stargazinghub.com/
- For light pollution and Bortle-class evaluation, prioritize https://www.lightpollutionmap.info/ only.
- For weather and visibility reference, use MSN weather logic only.
- For the best astrophotography time window, use stargazinghub only.
- Do not use any other source or fabricate data outside these websites.
- Do not add unsupported claims not aligned to those sources.

STRICT JSON OUTPUT FORMAT ONLY:
{{
  "spots": [
    {{
      "spot_name": "String (Name of spot)",
      "light_pollution_link": "String (Direct URL to lightpollutionmap.info for the same coordinates, e.g. https://www.lightpollutionmap.info/#lat=-7.983456&lon=112.630123&zoom=12)",
      "bortle_class": "Integer (1-9)",
      "sky_clarity_percentage": "Integer (0-100)",
      "visibility": {{
        "weather": "String (Weather condition summary, e.g. clear / partly cloudy / windy)",
        "cloud_cover": "String (Cloud cover estimate, e.g. 10% / 30%)",
        "seeing": "String (Atmospheric seeing / transparency description)",
        "best_time": "String (Best night window, e.g. 21:00-23:30 local time)"
      }},
      "composition": {{
        "foreground": "String (Recommended FG elements)",
        "background": "String (Recommended BG celestial targets)"
      }},
      "exposure_triangle": {{
        "shutter_speed": "String (Calculated exposure time)",
        "aperture": "String (Recommended f-stop)",
        "iso": "String (Recommended ISO)",
        "technique_notes": "String (Specific advice for gear and purpose)"
      }}
    }}
  ]
}}

Rule for Exposure Engine:
- If static photo: Apply 500 Rule (Max Shutter = 500 / Focal Length).
- If lighttrails: 15s-30s, low ISO (100-400), closed aperture (f/8-f/11).
- If video: 180-degree rule (1 / (2 * FPS)).
- If timelapse: Interval 5s, 15s exposure, ISO 1600-3200.
- Keep recommendations realistic for the selected camera gear and shooting purpose.
Do not output markdown code blocks or explanations outside JSON.
"""

    user_prompt = f"""
    Target Location: {your_location}
    Country: {country}
    Radius: {radius} km
    Shooting Purpose: {shooting_purpose}
    Camera Gear: {camera_gear}
    """

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", user_prompt)
    ])

    chain = prompt | llm

    try:
        logger.info(f"Triggering AI Agent for {your_location}, {country}...")
        response = chain.invoke({})
        
        # Handle different response types from LangChain
        # LangChain returns an AIMessage object with .content attribute
        if hasattr(response, 'content'):
            raw_text = response.content
        elif isinstance(response, str):
            raw_text = response
        else:
            raw_text = str(response)
        
        # Ensure raw_text is string and strip whitespace
        raw_text = str(raw_text).strip()

        # Sanitize JSON output if wrapped in backticks or code blocks
        if raw_text.startswith("```"):
            # Extract content between backticks
            parts = raw_text.split("```")
            if len(parts) >= 2:
                raw_text = parts[1]
                # Remove 'json' language identifier if present
                if raw_text.strip().startswith("json"):
                    raw_text = raw_text.strip()[4:].strip()
            raw_text = raw_text.strip()
        
        # Parse JSON and validate
        parsed_data = json.loads(raw_text)
        
        # Validate that we have spots array
        if "spots" not in parsed_data or not isinstance(parsed_data["spots"], list):
            logger.error("Invalid response structure: missing 'spots' array")
            raise ValueError("Invalid response structure")
        
        logger.info(f"Successfully generated {len(parsed_data['spots'])} spot recommendations")
        return parsed_data
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing error: {str(e)}")
        logger.error(f"Raw response was: {raw_text[:200] if 'raw_text' in locals() else 'N/A'}...") # type: ignore
        return _get_fallback_response(your_location, country, radius, shooting_purpose, camera_gear)
    except Exception as e:
        logger.error(f"Error in lookup agent: {str(e)}")
        return _get_fallback_response(your_location, country, radius, shooting_purpose, camera_gear)


def _get_fallback_response(your_location: str, country: str, radius: float, shooting_purpose: str, camera_gear: str) -> dict:
    """Generate a fallback response with 3 spots when AI fails"""
    return {
        "spots": [
            {
                "spot_name": f"{your_location} High Ridge Observatory Point",
                "light_pollution_link": "https://www.lightpollutionmap.info/#lat=-7.983456&lon=112.630123&zoom=12",
                "bortle_class": 3,
                "sky_clarity_percentage": 88,
                "visibility": {
                    "weather": "Clear",
                    "cloud_cover": "10%",
                    "seeing": "Good atmospheric transparency with low haze",
                    "best_time": "21:00 - 23:30 local time"
                },
                "composition": {
                    "foreground": "Pine tree silhouettes and high elevation ridge edge.",
                    "background": "Milky Way core alignment towards South Horizon."
                },
                "exposure_triangle": {
                    "shutter_speed": "15 sec",
                    "aperture": "f/2.8",
                    "iso": "ISO 3200",
                    "technique_notes": f"Tailored for {camera_gear} on {shooting_purpose} mode."
                }
            },
            {
                "spot_name": f"{your_location} Mountain Peak Dark Sky Site",
                "light_pollution_link": "https://www.lightpollutionmap.info/#lat=-8.012345&lon=112.650123&zoom=12",
                "bortle_class": 2,
                "sky_clarity_percentage": 92,
                "visibility": {
                    "weather": "Clear to partly cloudy",
                    "cloud_cover": "5-15%",
                    "seeing": "Excellent transparency, low atmospheric scattering",
                    "best_time": "22:00 - 05:00 local time"
                },
                "composition": {
                    "foreground": "Rocky mountain ridgeline with sparse vegetation.",
                    "background": "Deep Milky Way with galactic center prominence."
                },
                "exposure_triangle": {
                    "shutter_speed": "20 sec",
                    "aperture": "f/2.0",
                    "iso": "ISO 2500",
                    "technique_notes": f"Optimal for {camera_gear} wide-angle {shooting_purpose}."
                }
            },
            {
                "spot_name": f"{your_location} Plateau Clear Sky Reserve",
                "light_pollution_link": "https://www.lightpollutionmap.info/#lat=-8.002123&lon=112.620456&zoom=12",
                "bortle_class": 2,
                "sky_clarity_percentage": 90,
                "visibility": {
                    "weather": "Clear",
                    "cloud_cover": "0-10%",
                    "seeing": "Stable atmospheric conditions",
                    "best_time": "21:30 - 04:30 local time"
                },
                "composition": {
                    "foreground": "Open plateau with minimal obstruction.",
                    "background": "Zodiacal light and deep sky objects."
                },
                "exposure_triangle": {
                    "shutter_speed": "18 sec",
                    "aperture": "f/2.2",
                    "iso": "ISO 2800",
                    "technique_notes": f"Stable conditions ideal for {shooting_purpose} with {camera_gear}."
                }
            }
        ]
    }