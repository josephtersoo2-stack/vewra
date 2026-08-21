import json
import logging
import requests
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

def fetch_gemini_models(api_key: str) -> List[Dict[str, Any]]:
    """
    Dynamically queries Google Gemini API for available generation models.
    No hardcoded models.
    """
    if not api_key:
        raise ValueError("Gemini API key is required to fetch models.")

    url = f"{GEMINI_BASE_URL}/models?key={api_key}"
    response = requests.get(url, timeout=12)
    
    if response.status_code != 200:
        error_msg = response.text
        try:
            err_json = response.json()
            error_msg = err_json.get('error', {}).get('message', error_msg)
        except Exception:
            pass
        raise RuntimeError(f"Gemini API error ({response.status_code}): {error_msg}")

    data = response.json()
    models_raw = data.get('models', [])
    
    parsed_models = []
    for m in models_raw:
        methods = m.get('supportedGenerationMethods', [])
        # Only return models that support generateContent
        if 'generateContent' in methods:
            model_id = m.get('name', '')
            if model_id.startswith('models/'):
                model_id = model_id[len('models/'):]
            
            parsed_models.append({
                'id': model_id,
                'name': m.get('displayName', model_id),
                'description': m.get('description', ''),
                'input_token_limit': m.get('inputTokenLimit', 0),
            })
            
    # Sort with flash / 2.0 / 2.5 / 1.5 at the top
    parsed_models.sort(key=lambda x: ('flash' in x['id'].lower() or '2.5' in x['id'].lower() or '2.0' in x['id'].lower()), reverse=True)
    return parsed_models


def generate_keywords_gemini(
    api_key: str,
    model: str,
    video_data: Dict[str, Any],
    system_prompt: str
) -> List[str]:
    """
    Calls Google Gemini to generate high-relevance search keywords for the given video.
    """
    if not api_key:
        raise ValueError("Gemini API key is missing.")
    
    model_name = model.strip() if model else "gemini-2.5-flash"
    if model_name.startswith("models/"):
        model_name = model_name[len("models/"):]

    url = f"{GEMINI_BASE_URL}/models/{model_name}:generateContent?key={api_key}"
    
    user_prompt = f"""{system_prompt}

VIDEO DETAILS:
- Title: {video_data.get('title', '')}
- Channel / Author: {video_data.get('channel', video_data.get('author_name', ''))}
- Video ID: {video_data.get('video_id', '')}
- Description / Tags: {video_data.get('description', '')[:500]}

Return ONLY a JSON array of 6 to 10 high-ranking YouTube search phrases. Example format:
["phrase 1", "phrase 2", "phrase 3", "phrase 4", "phrase 5", "phrase 6"]
"""

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": user_prompt}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.3,
            "responseMimeType": "application/json"
        }
    }

    response = requests.post(url, json=payload, timeout=20)
    if response.status_code != 200:
        error_msg = response.text
        try:
            err_json = response.json()
            error_msg = err_json.get('error', {}).get('message', error_msg)
        except Exception:
            pass
        raise RuntimeError(f"Gemini generation error ({response.status_code}): {error_msg}")

    data = response.json()
    candidates = data.get('candidates', [])
    if not candidates:
        raise RuntimeError("Gemini returned no candidates.")

    text_content = candidates[0].get('content', {}).get('parts', [{}])[0].get('text', '')
    
    # Parse JSON output
    return _parse_json_keywords(text_content, fallback_title=video_data.get('title', ''))


def _parse_json_keywords(raw_text: str, fallback_title: str) -> List[str]:
    cleaned = raw_text.strip()
    # Strip markdown code fences if present
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()

    try:
        keywords = json.loads(cleaned)
        if isinstance(keywords, list):
            valid_list = [str(k).strip() for k in keywords if str(k).strip()]
            if valid_list:
                return valid_list
    except Exception as e:
        logger.warning(f"Failed to parse JSON from LLM: {e}, raw text: {cleaned}")

    # Fallback line-by-line parsing if not strict JSON
    lines = [line.strip().strip('-*•1234567890. "') for line in raw_text.splitlines() if line.strip()]
    if lines:
        return [l for l in lines if len(l) > 3][:10]

    return [fallback_title] if fallback_title else ["trending video"]
