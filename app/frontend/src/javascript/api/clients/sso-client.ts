import axios, { AxiosInstance } from 'axios';

function client (host: string): AxiosInstance {
  return axios.create({
    baseURL: host
  });
}

export default client;
