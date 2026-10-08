import urllib.request
import json
import sys

key = "AIzaSyDpMUlAvpSDedLPuQMYd9_wQflBMpqhuGk"
url = f"https://generativelanguage.googleapis.com/v1beta/models?key={key}"

try:
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode('utf-8'))
        print("Available Models:")
        for model in data.get('models', []):
            print(f"- {model['name']} ({model.get('displayName', '')})")
            print(f"  Supported methods: {model.get('supportedGenerationMethods', [])}")
except urllib.error.HTTPError as e:
    print(f"Error: {e.code} {e.reason}")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"Exception: {e}")
