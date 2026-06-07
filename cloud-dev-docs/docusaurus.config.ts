import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Cloud Dev Desktop',
  tagline: 'CDD is a containerized cloud development environment. Accessible from anywhere.',
  favicon: 'img/cloud_dev_desktop_logo.png',

  future: {
    v4: true,
  },

  url: 'https://Piero24.github.io',
  baseUrl: '/Cloud-Dev-Desktop/',

  organizationName: 'Piero24',
  projectName: 'Cloud-Dev-Desktop',

  onBrokenLinks: 'throw',
  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  themes: ['@docusaurus/theme-mermaid'],

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
            'https://github.com/Piero24/Cloud-Dev-Desktop/edit/main/cloud-dev-docs/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/cloud_dev_desktop_logo.png',
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'CDD',
      logo: {
        alt: 'Cloud Dev Desktop Logo',
        src: 'img/cloud_dev_desktop_logo.png',
      },
      items: [
        {
          to: '/docs/',
          label: 'Home',
          position: 'left',
        },
        {
          to: '/docs/server-setup',
          label: 'Getting Started',
          position: 'left',
        },
        {
          to: '/docs/env-vars',
          label: 'Reference',
          position: 'left',
        },
        {
          href: 'https://github.com/Piero24/Cloud-Dev-Desktop',
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
            {label: 'Daily Workflow', to: '/docs/daily-workflow'},
            {label: 'Environment Variables', to: '/docs/env-vars'},
            {label: 'Tips & Troubleshooting', to: '/docs/tips'},
          ],
        },
        {
          title: 'Resources',
          items: [
            {label: 'linuxserver/webtop', href: 'https://docs.linuxserver.io/images/docker-webtop/'},
            {label: 'linuxserver/code-server', href: 'https://docs.linuxserver.io/images/docker-code-server/'},
            {label: 'CasaOS', href: 'https://casaos.io/'},
          ],
        },
        {
          title: 'More',
          items: [
            {label: 'GitHub', href: 'https://github.com/Piero24/Cloud-Dev-Desktop'},
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Cloud Dev Desktop. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'yaml', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
