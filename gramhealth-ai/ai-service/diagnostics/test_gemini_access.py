import os
import sys

# Ensure ai-service root is in sys.path
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)
os.chdir(BASE_DIR)

from rag.config.settings import settings, get_gemini_api_key

def main():
    key = get_gemini_api_key()
    print("[GEMINI CONFIG]")
    print(f"GEMINI_API_KEY present: {bool(key)}")
    print(f"GEMINI_MODEL: {settings.gemini_model}")
    print(f"Key length: {len(key) if key else 0}")

    if not key:
        print("ERROR: No Gemini API key found in environment or .env file.")
        sys.exit(1)

    # 1. Test via Google GenAI SDK directly
    print("\n--- 1. Testing via google-genai Client directly ---")
    try:
        from google import genai
        client = genai.Client(api_key=key)
        print("Google client initialized: True")

        response = client.models.generate_content(
            model=settings.gemini_model,
            contents="Say OK"
        )
        print(f"Direct google-genai Success! Response: {response.text.strip()}")
    except Exception as e:
        print("Direct google-genai Failed!")
        print(f"Exception class: {type(e).__name__}")
        print(f"Exception module: {type(e).__module__}")
        print(f"Sanitized Message: {str(e)[:300]}")
        if hasattr(e, 'code'):
            print(f"Error code: {e.code}")
        if hasattr(e, 'details'):
            print(f"Error details: {e.details}")

    # 2. Test via ChatGoogleGenerativeAI (LangChain)
    print("\n--- 2. Testing via ChatGoogleGenerativeAI (LangChain) ---")
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI
        llm = ChatGoogleGenerativeAI(
            model=settings.gemini_model,
            google_api_key=key,
            temperature=0.0
        )
        res = llm.invoke("Say OK")
        if isinstance(res.content, list):
            content_str = " ".join([p.get("text", "") if isinstance(p, dict) else str(p) for p in res.content]).strip()
        else:
            content_str = str(res.content).strip()
        print(f"LangChain Success! Response: {content_str}")
    except Exception as e:
        print("LangChain Failed!")
        print(f"Exception class: {type(e).__name__}")
        print(f"Exception module: {type(e).__module__}")
        print(f"Sanitized Message: {str(e)[:300]}")

if __name__ == "__main__":
    main()
