# AAHAR_APP (Krishi AI)

Aahar is a precision agriculture Flutter application designed to assist Indian farmers with actionable insights. This app features **Krishi AI**, an intelligent RAG-based chatbot that provides guidance on government farming schemes, crop rotation, and agricultural best practices.

## Features

- **Krishi AI Chatbot**: An interactive chatbot using Google's Gemini API (`gemini-2.5-flash` for chat generation and `gemini-embedding-2` for embeddings).
- **RAG System (Retrieval-Augmented Generation)**: The app processes PDF documents locally (such as government scheme compendiums and crop rotation guides) and caches them in a local vector store.
- **Text-to-Speech (TTS)**: The chatbot supports playing back responses using TTS with auto-detection for English and Hindi.
- **Source Citations**: AI responses include citations (document name and page number) to provide reliable and verifiable answers based on the provided PDF corpus.

## Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ishan7540/AAHAR_APP.git
   cd aahar_app
   ```

2. **API Key Setup**:
   - Get a Gemini API Key from [Google AI Studio](https://aistudio.google.com/apikey).
   - Create a `.env` file in the root directory.
   - Add your API key to the file:
     ```env
     GEMINI_API_KEY=YOUR_API_KEY_HERE
     ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the Application**:
   ```bash
   flutter run
   ```

## Technologies Used

- **Flutter & Dart**: Cross-platform application framework.
- **Gemini API**: Generative AI models for text embeddings and chat generation.
- **Syncfusion Flutter PDF**: Pure Dart library for extracting text from PDFs.
- **Flutter TTS**: Text-to-speech implementation.
- **Fl_chart**: For dashboard charts (if applicable).

## License

This project relies on the Syncfusion Community License for the `syncfusion_flutter_pdf` package. Please ensure you comply with their licensing terms if modifying or distributing this application.
