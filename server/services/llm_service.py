import google.genai as genai
from google.genai import types
from config import Settings

settings = Settings()


class LLMService:
    def __init__(self):
        if not settings.GEMINI_API_KEY:
            print("ERROR: GEMINI_API_KEY is not set in environment")
            self.client = None
            self.model_name = None
            return
            
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)
        self.model_name = None

        # Use gemini-1.5-flash as default model
        self.model_name = "gemini-1.5-flash"
        print(f"Initialized LLM service with model: {self.model_name}")
        
        if not self.model_name:
            print("ERROR: No valid Gemini model could be initialized. Check API key permissions.")

    def generate_response(self, query: str, search_results: list[dict]):
        """Yield response text chunks; on error, yield a human-readable message."""

        context_text = "\n\n".join(
            [
                f"Source {i+1} ({result.get('url','')}):\n{result.get('content','')}"
                for i, result in enumerate(search_results or [])
            ]
        )

        full_prompt = f"""
        Context from web search:
        {context_text}

        Query: {query}

        Provide a comprehensive, well-cited accurate response using the above context.
        Think and reason deeply. Prefer cited facts from sources; only use prior knowledge if necessary.
        """

        if not self.model_name:
            yield (
                "LLM unavailable: no valid Gemini model configured. "
                "Please set GEMINI_API_KEY and ensure model access."
            )
            return

        try:
            stream = self.client.models.stream_generate_content(
                model=self.model_name,
                contents=full_prompt,
                config=types.GenerateContentConfig(temperature=0.4),
            )

            for chunk in stream:
                text = getattr(chunk, "text", None)

                if not text and getattr(chunk, "candidates", None):
                    parts = chunk.candidates[0].content.parts
                    if parts:
                        text = getattr(parts[0], "text", None)

                if text:
                    yield text
        except Exception as e:
            yield f"Error generating response from {self.model_name}: {e}"