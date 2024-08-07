require('dotenv').config();
const axios = require('axios');

module.exports.getCoordinates = async (location) => {
  try {
    // Make a GET request to the Google Geocode API to retrieve the coordinates for the given address
    const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
      params: {
        address: `${location}, San Francisco, California`,
        key: process.env.MAPS_API_KEY,
      },
    });

    // Extract the latitude and longitude from the response
    const lat = response.data.results[0].geometry.location.lat;
    const lng = response.data.results[0].geometry.location.lng;

    // Return the coordinates as an object
    return { lat, lng };
  } catch (error) {
    console.error(error);
  }
};

const getNamedEntities = async (transcript, useExpensiveModel = false) => {
  const model = useExpensiveModel
    ? 'Jean-Baptiste/roberta-large-ner-english'
    : 'dbmdz/bert-large-cased-finetuned-conll03-english';

  if (useExpensiveModel) {
    console.info('Using expensive model...');
  }

  try {
    const { data } = await axios.post(
      `https://api-inference.huggingface.co/models/${model}`,
      {
        inputs: transcript,
        options: {
          wait_for_model: useExpensiveModel,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.HUGGINGFACE_API_KEY2}`,
        },
      }
    );

    if (data?.error) {
      console.log('request resolved with error', data);

      return {
        name: undefined,
        location: undefined,
      };
    }

    const namedEntities = (data ?? []).sort(({ score: scoreA }, { score: scoreB }) => scoreB - scoreA);
    const name = namedEntities.find(({ entity_group }) => entity_group === 'PER')?.word;
    const location = namedEntities.find(({ entity_group }) => ['LOC', 'ORG'].includes(entity_group))?.word;

    return { name, location };
  } catch (error) {
    console.error('Error finding named entities', error);

    return {
      name: undefined,
      location: undefined,
    };
  }
};

const getEmergencyType = async (transcript) => {
  try {
    const { data } = await axios.post(
      'https://api-inference.huggingface.co/models/facebook/bart-large-mnli',
      {
        inputs: transcript,
        parameters: {
          candidate_labels: [
            'medical emergency',
            'fire emergency',
            'traffic accident',
            'crime in progress',
            'other emergency',
          ],
        },
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
        },
      }
    );

    if (!data || !data?.labels || !data.labels.length) {
      console.log('request resolved with missing data', data);

      return {
        emergencyType: undefined,
      };
    }

    return {
      emergencyType: data.labels[0].replace(/\b[a-z]/gi, (c) => c.toUpperCase()),
    };
  } catch (error) {
    console.error('Error finding emergency type', error);

    return {
      emergencyType: undefined,
    };
  }
};

module.exports.analyzeTranscript = async (transcript) => {
  try {
    const strippedTranscript = transcript.replace(/[A-Z.]/g, char => char.toLowerCase()).replace(/\./g, "");

    const { name, location } = await getNamedEntities(strippedTranscript);
    const { emergencyType } = await getEmergencyType(strippedTranscript);

    return {
      name,
      location,
      emergencyType,
    };
  } catch (error) {
    console.error(error);
  }
};

module.exports.getNamedEntities = (transcript, useExpensiveModel = false) => {
  const strippedTranscript = transcript.replace(/[A-Z.]/g, char => char.toLowerCase()).replace(/\./g, "");
  return getNamedEntities(strippedTranscript, useExpensiveModel);
};

module.exports.analyzePriority = (transcript) => {
  // Use regex to search for keywords that indicate a high-priority call
  const highPriorityKeywords = [
    'shots',
    'kill',
    'gun',
    'shot',
    'fire',
    'injured',
    'robb',
    'assault',
    'murder',
    'homicide',
    'kidnap',
    'armed',
    'suspect',
    'explosion',
    'dead',
    'die',
  ];
  const highPriorityRegex = new RegExp(highPriorityKeywords.join('|'), 'gi');

  // Use regex to search for keywords that indicate a medium-priority call
  const mediumPriorityKeywords = [
    'suspicious',
    'traffic',
    'accident',
    'noise',
    'complaint',
    'missing person',
    'animal',
    'bite',
    'vandalism',
    'fight',
    'break-in',
  ];
  const mediumPriorityRegex = new RegExp(mediumPriorityKeywords.join('|'), 'gi');

  // Use regex to search for keywords that indicate a low-priority call
  const lowPriorityKeywords = ['lost', 'property', 'inquiry', 'advice', 'noise', 'graffiti'];
  const lowPriorityRegex = new RegExp(lowPriorityKeywords.join('|'), 'gi');

  // Check if transcript contains any high-priority keywords
  if (transcript.match(highPriorityRegex)) {
    return 'HIGH';
  }
  // Check if transcript contains any medium-priority keywords
  else if (transcript.match(mediumPriorityRegex)) {
    return 'MEDIUM';
  }
  // Check if transcript contains any low-priority keywords
  else if (transcript.match(lowPriorityRegex)) {
    return 'LOW';
  }
  // If no keywords are found, return unknown priority
  else {
    return 'TBD';
  }
};
