import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}', './lib/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#effdfb',
          600: '#0f8b8d',
          700: '#0b7173',
        },
      },
    },
  },
  plugins: [],
};

export default config;
