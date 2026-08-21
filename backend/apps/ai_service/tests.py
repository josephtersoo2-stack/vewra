from django.test import TestCase
from django.urls import reverse
from unittest.mock import patch, MagicMock

from apps.ai_service.models import AISettings
from apps.ai_service.services import (
    extract_youtube_video_id,
    extract_youtube_metadata,
    generate_smart_fallback_keywords,
    generate_video_keywords,
    get_available_models,
)
from apps.ai_service.providers.gemini import fetch_gemini_models, generate_keywords_gemini
from apps.ai_service.providers.openrouter import fetch_openrouter_models, generate_keywords_openrouter
from apps.tasks.models import VideoTask
from apps.tasks.services import generate_randomized_instruction


class AIServiceTests(TestCase):
    def setUp(self):
        self.settings = AISettings.get_settings()
        self.settings.gemini_api_key = "test-gemini-key"
        self.settings.openrouter_api_key = "test-openrouter-key"
        self.settings.save()

    def test_extract_youtube_video_id(self):
        urls = [
            ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://youtu.be/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=10s", "dQw4w9WgXcQ"),
            ("https://www.youtube.com/embed/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://www.youtube.com/shorts/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ]
        for url, expected in urls:
            self.assertEqual(extract_youtube_video_id(url), expected)

    @patch('requests.get')
    def test_extract_youtube_metadata(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            'title': 'Flutter in 100 Seconds',
            'author_name': 'Fireship',
            'thumbnail_url': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        }
        mock_get.return_value = mock_resp

        meta = extract_youtube_metadata("https://youtu.be/dQw4w9WgXcQ")
        self.assertEqual(meta['video_id'], 'dQw4w9WgXcQ')
        self.assertEqual(meta['title'], 'Flutter in 100 Seconds')
        self.assertEqual(meta['channel'], 'Fireship')

    def test_generate_smart_fallback_keywords(self):
        keywords = generate_smart_fallback_keywords(
            title="Flutter in 100 Seconds | Complete Tutorial",
            channel="Fireship"
        )
        self.assertTrue(len(keywords) >= 2)
        self.assertTrue(any("Flutter in 100 Seconds" in k for k in keywords))

    @patch('requests.get')
    def test_fetch_gemini_models_dynamic(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            'models': [
                {
                    'name': 'models/gemini-2.5-flash',
                    'displayName': 'Gemini 2.5 Flash',
                    'supportedGenerationMethods': ['generateContent', 'countTokens'],
                    'description': 'Fast and intelligent model',
                },
                {
                    'name': 'models/embedding-001',
                    'displayName': 'Embedding 001',
                    'supportedGenerationMethods': ['embedContent'],
                }
            ]
        }
        mock_get.return_value = mock_resp

        models = fetch_gemini_models("fake-key")
        self.assertEqual(len(models), 1)
        self.assertEqual(models[0]['id'], 'gemini-2.5-flash')
        self.assertEqual(models[0]['name'], 'Gemini 2.5 Flash')

    @patch('requests.get')
    def test_fetch_openrouter_models_dynamic(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            'data': [
                {
                    'id': 'google/gemini-2.5-flash',
                    'name': 'Google: Gemini 2.5 Flash',
                    'description': 'Fast multimodal model',
                    'context_length': 1000000,
                },
                {
                    'id': 'meta-llama/llama-3.3-70b-instruct',
                    'name': 'Meta: Llama 3.3 70B Instruct',
                    'description': 'Open weights flagship model',
                    'context_length': 128000,
                }
            ]
        }
        mock_get.return_value = mock_resp

        models = fetch_openrouter_models("fake-key")
        self.assertEqual(len(models), 2)
        model_ids = [m['id'] for m in models]
        self.assertIn('google/gemini-2.5-flash', model_ids)
        self.assertIn('meta-llama/llama-3.3-70b-instruct', model_ids)

    @patch('requests.post')
    def test_generate_keywords_gemini(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            'candidates': [
                {
                    'content': {
                        'parts': [
                            {
                                'text': '["Flutter in 100 Seconds Fireship", "Flutter mobile development tutorial", "Fireship cross platform app"]'
                            }
                        ]
                    }
                }
            ]
        }
        mock_post.return_value = mock_resp

        keywords = generate_keywords_gemini(
            api_key="fake-key",
            model="gemini-2.5-flash",
            video_data={'title': 'Flutter in 100 Seconds', 'channel': 'Fireship', 'video_id': '12345678901'},
            system_prompt="Generate keywords"
        )
        self.assertEqual(len(keywords), 3)
        self.assertEqual(keywords[0], "Flutter in 100 Seconds Fireship")

    def test_randomized_instruction_uses_full_phrase(self):
        task = VideoTask.objects.create(
            youtube_url="https://youtu.be/dQw4w9WgXcQ",
            video_id="dQw4w9WgXcQ",
            title="Never Gonna Give You Up",
            keywords=[
                "Never Gonna Give You Up Rick Astley",
                "Rick Astley official music video",
                "Rick Astley 80s classic pop hit"
            ],
            reward_type="per_time",
            reward_config={"coins": 10, "seconds": 60}
        )

        instruction = generate_randomized_instruction(task)
        self.assertIn(instruction['search_query'], task.keywords)
        self.assertIn("Never Gonna Give You Up", instruction['full_instruction'])

    def test_api_generate_keywords_endpoint(self):
        response = self.client.post(
            reverse('ai-generate-keywords'),
            data={'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'},
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['video_id'], 'dQw4w9WgXcQ')
        self.assertTrue(len(data['keywords']) > 0)
