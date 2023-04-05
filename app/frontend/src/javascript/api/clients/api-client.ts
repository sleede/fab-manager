import axios, { AxiosInstance } from 'axios';
import ParsingLib from '../../lib/parsing';

type Error = { error: string };

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
  // 304 Not Modified should be considered as a success
  if (error.response?.status === 304) { return Promise.resolve(error.response); }

  // Any status codes that falls outside the range of 2xx cause this function to trigger
  const message = error.response?.data || error.message || error;
  return Promise.reject(extractHumanReadableMessage(message));
});

function extractHumanReadableMessage (error: string|Error): string {
  if (typeof error === 'string') {
    if (error.match(/^<!DOCTYPE html>/)) {
      // parse ruby error pages (when an unhandled exception is raised)
      const parser = new DOMParser();
      const htmlDoc = parser.parseFromString(error, 'text/html');
      if (htmlDoc.querySelectorAll('h2').length > 2) {
        return htmlDoc.querySelector('h2').textContent;
      } else {
        if (htmlDoc.querySelector('.exception-message .message')) {
          return htmlDoc.querySelector('.exception-message .message').textContent;
        }
        return htmlDoc.querySelector('h1').textContent;
      }
    }
    return error;
  }

  // parse Rails errors (as JSON) or API errors (i.e. the API returns a JSON like {error: ...})
  let message = '';
  if (error instanceof Object) {
    // API errors
    if (Object.prototype.hasOwnProperty.call(error, 'error') && typeof error.error === 'string') {
      return error.error;
    }
    // iterate through all the keys to build the message
    for (const key in error) {
      if (Object.prototype.hasOwnProperty.call(error, key)) {
        if (!ParsingLib.isInteger(key)) {
          message += `${key} : `;
        }
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
