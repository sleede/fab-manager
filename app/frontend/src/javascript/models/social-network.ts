export interface SocialNetwork {
  name: string,
  url: string
}

export const supportedNetworks = [
  'facebook',
  'twitter',
  'viadeo',
  'linkedin',
  'instagram',
  'youtube',
  'vimeo',
  'dailymotion',
  'github',
  'echosciences',
  'pinterest',
  'lastfm',
  'flickr'
] as const;

export type SupportedSocialNetwork = typeof supportedNetworks[number];
