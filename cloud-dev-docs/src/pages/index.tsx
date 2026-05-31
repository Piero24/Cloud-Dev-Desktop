import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

const features = [
  {
    title: 'Browser-Based Desktop',
    emoji: '🖥️',
    description:
      'Full Ubuntu XFCE desktop in your browser via linuxserver/webtop. Accessible from any device — no remote desktop client needed.',
  },
  {
    title: 'Full Bidirectional Sync',
    emoji: '🔄',
    description:
      'Edit files locally on your Mac. Changes sync to the server automatically via rsync through a multiplexed SSH tunnel — including deletions. No background daemon required.',
  },
  {
    title: '2FA Protected',
    emoji: '🔒',
    description:
      'Cloudflare Zero Trust 2FA gates all web access. SSH is protected by password + optional TOTP 2FA at session start, then reused for hours via ControlMaster multiplexing.',
  },
  {
    title: 'VS Code Everywhere',
    emoji: '📝',
    description:
      'Browser-based VS Code (code-server) on a separate port. Shares the same /projects volume with the desktop container — same files, instant visibility.',
  },
  {
    title: 'Persistent Dev Environment',
    emoji: '💾',
    description:
      'All user-installed packages, tools, and configs survive container rebuilds. nvm, Node LTS, Claude Code, Python, and build tools come pre-installed. Add more anytime.',
  },
  {
    title: 'One-Click Reset',
    emoji: '🔄',
    description:
      'Kill switch built in. Wipe all user state with one command and get a fresh container on next boot — without touching your project files.',
  },
];

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/server-setup">
            Get Started — Server Setup →
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Cloud Dev Stack"
      description="A containerized cloud development environment for CasaOS — Ubuntu desktop, VS Code, and SSH all sharing the same /projects folder.">
      <HomepageHeader />
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              {features.map(({title, emoji, description}, idx) => (
                <div key={idx} className={clsx('col col--4', styles.featureItem)}>
                  <div className="feature-card">
                    <div className="feature-icon">{emoji}</div>
                    <Heading as="h3">{title}</Heading>
                    <p>{description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
