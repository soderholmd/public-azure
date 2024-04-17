'''
Azure OpenAI text summariser
Daniel Soderholm 2024
Version 1.1 - 2024-04-17

The code is a Python script that uses the Azure OpenAI API to generate text summaries. 
It takes command line arguments to specify the input text, either from a file (TXT/DOCX/PDF) or a URL, and allows the user to interactively enter a prompt if no file or URL is provided. 
The script sends a request to the Azure OpenAI model, passing the input text as a message. 
The generated summary is then printed to the console. 
If the --stats flag is included, the script also prints statistics about the token usage and cost of the transaction.

URLs might not work because they generate a lot of text and the API has a limit on the number of tokens that can be processed in a single request. 

The script uses the AzureOpenAI class from the OpenAI module to interact with the Azure OpenAI API. 

The script also reads the Azure OpenAI endpoint and key from the .env file using the dotenv package.
'''

import os
import argparse
import requests
import time
import PyPDF2
from dotenv import load_dotenv
from docx import Document

# Add Azure OpenAI package
from openai import AzureOpenAI

# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument('--file', help='Path to a text file for input text')
parser.add_argument('--url', help='URL to read input text from')
parser.add_argument('--stats', action='store_true', help='Show OpenAI statistics')
parser.add_argument('--gpt4', action='store_true', help='Use GPT-4 model for summarisation')
args = parser.parse_args()

def main(): 
        
    try: 
    
        # Get configuration settings 
        load_dotenv()
        azure_oai_endpoint = os.getenv("AZURE_OAI_ENDPOINT")
        azure_oai_key = os.getenv("AZURE_OAI_KEY")
        
        # Set azure_oai_deployment based on --gpt4 flag
        if args.gpt4:
            azure_oai_deployment = os.getenv("AZURE_OAI_DEPLOYMENT_GPT4")
        else:
            azure_oai_deployment = os.getenv("AZURE_OAI_DEPLOYMENT")
        
        # Initialize the Azure OpenAI client...
        client = AzureOpenAI(
        azure_endpoint = azure_oai_endpoint, 
        api_key=azure_oai_key,  
        api_version="2024-02-15-preview"
        )
    
        # Create a system message
        with open('system_message.txt', 'r') as file:
            system_message = file.read()

        # Get input text
        if args.file:
            if args.file.endswith('.docx'):
                doc = Document(args.file)
                input_text = ' '.join(paragraph.text for paragraph in doc.paragraphs)
            elif args.file.endswith('.pdf'):
                with open(args.file, 'rb') as file:
                    reader = PyPDF2.PdfReader(file)
                    input_text = ' '.join(reader.pages[i].extract_text() for i in range(len(reader.pages)))
            else:
                with open(args.file, 'r') as file:
                    input_text = file.read()
        elif args.url:
            webcontent = requests.get(args.url)
            webcontent.raise_for_status()  # Raise an exception if the GET request failed
            input_text = webcontent.text
        else:
            input_text = input("Enter the prompt ('quit' to exit): ")
            if len(input_text) == 0:
                print("Please enter a prompt.")

        print("\nSending request for summary to Azure OpenAI endpoint...\n\n")

        # Start the timer
        if args.stats:
            start_time = time.time()

        # Send request to Azure OpenAI model
        response = client.chat.completions.create(
            model=azure_oai_deployment,
            temperature=0.7,
            max_tokens=500,
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": input_text}
            ]
        )
        generated_text = response.choices[0].message.content

        # Print the response
        print("====================================")
        print("Response:")
        print("====================================" + "\n")
        print(generated_text + "\n")

        # Print the number of tokens used if --stats flag is included
        if args.stats:
            print("====================================")
            print("Statistics:")
            print("------------------------------------")

            # Print the token usage
            print(f"Prompt tokens: {response.usage.prompt_tokens}")
            print(f"Completion tokens: {response.usage.completion_tokens}")
            print(f"Total tokens: {response.usage.total_tokens}")
            print("------------------------------------")

            # Calculate the total word count
            input_word_count = len(input_text.split())
            system_word_count = len(system_message.split())
            total_word_count = input_word_count + system_word_count
            print(f"Prompt word count: {total_word_count}")
            response_word_count = len(generated_text.split())
            print(f"Response word count: {response_word_count}")
            print(f"Prompt tokens per word: {response.usage.prompt_tokens / total_word_count:.1f}")
            print(f"Completion tokens per word: {response.usage.completion_tokens / response_word_count:.1f}")
            print("------------------------------------")

            # Calculate the cost of the transaction
            # Make sure the costs here are correct depending on which model you are using
            if args.gpt4:
                cost_per_input_token = 0.06 / 1000
                cost_per_output_token = 0.12 / 1000
            else:
                cost_per_input_token = 0.003 / 1000
                cost_per_output_token = 0.004 / 1000
            prompt_token_cost = response.usage.prompt_tokens * cost_per_input_token
            completion_token_cost = response.usage.completion_tokens * cost_per_output_token
            total_cost = prompt_token_cost + completion_token_cost
            print(f"Prompt token cost: ${prompt_token_cost:.3f}")
            print(f"Completion token cost: ${completion_token_cost:.3f}")
            print(f"Total cost: ${total_cost:.3f}")
            print("------------------------------------")

            # Stop the timer
            elapsed_time = time.time() - start_time
            print(f"Request took {round(elapsed_time, 2)} seconds.")
            print("====================================" + "\n")
            
    except Exception as ex:
        print(ex)

if __name__ == '__main__': 
    main()
