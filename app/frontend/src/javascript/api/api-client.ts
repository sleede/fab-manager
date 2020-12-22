import axios, { AxiosInstance } from 'axios'

const token: HTMLMetaElement = document.querySelector('[name="csrf-token"]');
const client: AxiosInstance = axios.create({
  headers: {
    common: {
      'X-CSRF-Token': token?.content || 'no-csrf-token'
    }
  }
});

client.interceptors.response.use(function (response) {
  // Any status code that lie within the range of 2xx cause this function to trigger
  return response;
}, function (error) {
  // Any status codes that falls outside the range of 2xx cause this function to trigger
  const message = error.response?.data || error.message || error;
  return Promise.reject(extractHumanReadableMessage(message));
});

function extractHumanReadableMessage(error: any): string {
  if (error.match(/^<!DOCTYPE html>/)) {
    // parse ruby error pages
    const parser = new DOMParser();
    const htmlDoc = parser.parseFromString(error, 'text/html');
    return htmlDoc.querySelector('h2').textContent;
  }

  if (typeof error === 'string') return error;

  // parse Rails errors (as JSON)
  let message = '';
  if (error instanceof Object) {
    // iterate through all the keys to build the message
    for (const key in error) {
      if (Object.prototype.hasOwnProperty.call(error, key)) {
        message += `${key} : `;
        if (error[key] instanceof Array) {
          // standard rails messages are stored as {field: [error1, error2]}
          // we rebuild them as "field: error1, error2"
          message += error[key].join(', ');
        } else {
          message += error[key];
        }
      }
    }
    return message;
  }

  return JSON.stringify(error);
}

export default client;
