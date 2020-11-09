import axios, { AxiosInstance } from 'axios'

const token: HTMLMetaElement = document.querySelector('[name="csrf-token"]');
const client: AxiosInstance = axios.create({
  headers: {
    common: {
      'X-CSRF-Token': token?.content || 'no-csrf-token'
    }
  }
})

export default client;
