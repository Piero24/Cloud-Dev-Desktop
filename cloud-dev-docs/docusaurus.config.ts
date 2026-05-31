import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Cloud Dev Stack',
  tagline: 'A containerized cloud development environment for CasaOS — accessible from anywhere, protected by 2FA.',
  favicon: 'img/favicon.ico',

  // Future flags
  future: {
    v4: true,
  },

  // CHANGE THESE: Replace with your GitHub username + repo name
  // After creating the repo, the URL will be: https://<username>.github.io/<repo>/
  url: 'https://example.github.io',
  baseUrl: '/cloud-dev-stack/',

  organizationName: 'your-github-username',
  projectName: 'cloud-dev-stack',

  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: 'docs',
          editUrl:
            'https://github.com/your-github-username/cloud-dev-stack/edit/main/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/logo.svg',
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Cloud Dev Stack',
      logo: {
        alt: 'Cloud Dev Stack Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          to: '/',
          label: 'Home',
          position: 'left',
        },
        {
          to: '/docs/server-setup',
          label: 'Server Setup',
          position: 'left',
        },
        {
          to: '/docs/mac-setup',
          label: 'Mac Setup',
          position: 'left',
        },
        {
          to: '/docs/tips',
          label: 'Tips',
          position: 'left',
        },
        {
          href: 'https://github.com/your-github-username/cloud-dev-stack',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {label: 'Overview & Architecture', to: '/docs/'},
            {label: 'Server Setup', to: '/docs/server-setup'},
            {label: 'Mac Setup', to: '/docs/mac-setup'},
            {label: 'Daily Workflow', to: '/docs/daily-workflow'},
            {label: 'Persistence & Kill Switch', to: '/docs/persistence'},
            {label: 'Tips & Troubleshooting', to: '/docs/tips'},
          ],
        },
        {
          title: 'Resources',
          items: [
            {label: 'linuxserver/webtop', href: 'https://docs.linuxserver.io/images/docker-webtop/'},
            {label: 'linuxserver/code-server', href: 'https://docs.linuxserver.io/images/docker-code-server/'},
            {label: 'CasaOS', href: 'https://casaos.io/'},
            {label: 'Cloudflare Zero Trust', href: 'https://www.cloudflare.com/products/zero-trust/'},
          ],
        },
        {
          title: 'More',
          items: [
            {label: 'GitHub', href: 'https://github.com/<your-github-username>/cloud-dev-stack'},
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Cloud Dev Stack. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'yaml', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
