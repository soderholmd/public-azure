# Azure OpenAI Text Summariser

Daniel Soderholm 2024

The code is a Python script that uses the Azure OpenAI API to generate text summaries. 
It takes command line arguments to specify the input text, either from a file or a URL, and allows the user to interactively enter a prompt if no file or URL is provided. 
The script sends a request to the Azure OpenAI model, passing the input text as a message. The generated summary is then printed to the console. 
If the --stats flag is included, the script also prints statistics about the token usage and cost of the transaction.
URLs might not work because they generate a lot of text and the API has a limit on the number of tokens that can be processed in a single request. 
The script uses the AzureOpenAI class from the OpenAI module to interact with the Azure OpenAI API. 
It defaults to GPT-3.5 (or whatever you save as AZURE_OAI_DEPLOYMENT), but has a flag to use GPT-4 instead. 
GPT-4 will provide better results but runs about 10x slower than GPT-3.5, and costs about 50% more.
The script also reads the Azure OpenAI endpoint and key from the .env file using the dotenv package.
