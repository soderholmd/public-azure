# Azure OpenAI Text Summariser

_Daniel Soderholm 2024_

The code is a Python script that uses the Azure OpenAI API to generate text summaries. It's intended to play with the OpenAI API and can be used for learning and experimentation.

It takes command line arguments to specify the input text, either from a file (TXT/DOC/PDF) or a URL (using the `--file` and `--url` parameters), and allows the user to interactively enter a prompt if no file or URL is provided.

The script sends a request to the Azure OpenAI model, passing the input text as a message. The generated summary is then printed to the console. 

If the `--stats` flag is included, the script also prints statistics about the token usage and cost of the transaction.

URLs might not work because they generate a lot of text and the API has a limit on the number of tokens that can be processed in a single request. 

The script uses the `AzureOpenAI` class from the `OpenAI` module to interact with the Azure OpenAI API. 

It defaults to GPT-3.5 (or whatever you save as `AZURE_OAI_DEPLOYMENT`), but has a flag (`--gpt4`) to use GPT-4 instead. GPT-4 will provide better results but runs about 10-20x slower than GPT-3.5, and costs about 50% more.

The script also reads the Azure OpenAI endpoint and key from the `.env` file.

You will need to create the necessary OpenAI service in Azure with GPT-3.5 and/or GPT-4 deployments, and add the environment varibales to the `.env` file. Also make sure the model costs are correct for the model you are using.

Tweak the system prompt (in `system_message.txt`) to see what works best, or change it to do something else like give holiday tips or write poetry. You can also change `temperature` and `max_tokens` to get different results.
