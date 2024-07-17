import { HuggingFaceTransformersEmbeddings } from "@langchain/community/embeddings/hf_transformers";
import { ChatGroq } from '@langchain/groq';
import { PromptTemplate } from '@langchain/core/prompts';
import { Index } from "@upstash/vector";
import { RecursiveCharacterTextSplitter } from 'langchain/text_splitter';
import dotenv from 'dotenv';

dotenv.config();

const embeddingModel = new HuggingFaceTransformersEmbeddings({
  model: "Xenova/all-MiniLM-L6-v2",
});

const groqModel = new ChatGroq({
  apiKey: process.env.GROQ_API_KEY,
  model: "llama3-8b-8192",
  temperature: 0,
});

const index = new Index({
  url: process.env.UPSTASH_VECTOR_URL,
  token: process.env.UPSTASH_VECTOR_TOKEN,
});

const promptTemplate = new PromptTemplate({
  template: `Use the following context to answer the question. 
  If the answer cannot be found in the context, say "I am sorry I couldn't resolve your query! Do you need me to connect you with admin?".


  Context:
  >>>
  {context}
  >>>

  Question: {question}`,
  inputVariables: ['context', 'question']
});

const textSplitter = new RecursiveCharacterTextSplitter({
  chunkSize: 300, // Adjust chunk size
  chunkOverlap: 100, // Increase overlap for better context preservation
});

export async function addDocument(domain, content) {
  console.log(`Adding document for domain: ${domain}`);
  const chunks = await textSplitter.createDocuments([content]);
  
  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    const embedding = await embeddingModel.embedQuery(chunk.pageContent);
    await index.upsert([
      {
        id: `${domain}-${i}`,
        vector: embedding,
        metadata: { content: chunk.pageContent, domain: domain }
      }
    ]);
  }
  console.log(`Document added for domain: ${domain}`);
}

async function queryVectorStore(domain, query) {
  const embedding = await embeddingModel.embedQuery(query);
  const results = await index.query({ vector: embedding, topK: 5, includeMetadata: true }); // Increase topK for more results
  const filteredResults = results.filter(result => result.metadata.domain === domain);
  
  if (filteredResults.length > 0) {
    return filteredResults.map(match => match.metadata.content).join("\n\n");
  } else {
    return "No relevant information found.";
  }
}

export async function queryAndRespond(domain, userQuery) {
  const context = await queryVectorStore(domain, userQuery);

  const prompt = await promptTemplate.format({
    context: context,
    question: userQuery
  });


  const response = await groqModel.invoke(prompt);
  return response;
}
