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
      'Full Ubuntu XFCE desktop in your browser via linuxserver/webtop. Accessible from any device no remote desktop client needed.',
  },
  {
    title: 'Full Bidirectional Sync',
    emoji: '🔄',
    description:
      'Edit files locally on your Mac. Changes sync to the server automatically via rsync through a multiplexed SSH tunnel including deletions. No background daemon required.',
  },
  {
    title: 'VS Code Everywhere',
    emoji: '📝',
    description:
      'Browser-based VS Code (code-server) on a separate port. Shares the same /projects volume with the desktop container same files, instant visibility.',
  },
  {
    title: 'Persistent Dev Environment',
    emoji: '💾',
    description:
      'Your entire workspace nvm, Node LTS, Claude Code, Python, Go, and build tools comes pre-installed. User packages and configs survive container rebuilds. Add more anytime via the init script.',
  },
  {
    title: 'One-Click Reset',
    emoji: '🔄',
    description:
      'Kill switch built in. Wipe all user state with one command and get a fresh container on next boot without touching your project files.',
  },
  {
    title: 'Works on Anything',
    emoji: '🌐',
    description:
      'Browser-based desktop and VS Code, plus SSH. Connect from any device laptop, tablet, or phone. No client installs, no platform lock-in.',
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
      description="A containerized cloud development environment: Ubuntu desktop, VS Code, and SSH all sharing the same /projects folder.">
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
