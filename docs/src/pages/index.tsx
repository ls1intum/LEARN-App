import type { ReactNode } from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import styles from './index.module.css';

function HomepageHeader() {
  return (
    <header
      className={clsx('hero hero--primary', styles.heroBanner)}
      style={{
        paddingBottom: '3rem',
      }}
    >
      <div className="container">
        <Heading as="h1" className="hero__title">
          Welcome to the LEARNHub User Documentation
        </Heading>
        <p className="hero__subtitle">
          Discover, plan, and manage classroom-ready computer science activities with ease.
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/learn-app/create-activity-recommendations">
            Get Started →
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout
      title="LEARNApp Documentation"
      description="LEARNApp User Documentation — discover, plan, and manage computer science activities for the classroom.">
      <HomepageHeader />
      <main
        style={{
          maxWidth: 900,
          margin: '3rem auto',
          padding: '0 1.5rem',
          textAlign: 'center',
        }}
      >

        {/* LEARN acronym section */}
        <div
          style={{
            margin: '0 auto 2rem',
            padding: '1.2rem 1rem',
            background: 'linear-gradient(135deg, #f5f7fa 0%, #e4ecf7 100%)',
            borderRadius: 12,
            boxShadow: '0 4px 10px rgba(0, 0, 0, 0.1)',
            textAlign: 'center',
            maxWidth: 650,
          }}
        >
          <h3 style={{ marginBottom: '1.2rem' }}>
            What does <span style={{ color: '#0078e7' }}>LEARN</span> stand for?
          </h3>

          {/* Inner box */}
          <div
            style={{
              borderRadius: 8,
              display: 'inline-block',
              padding: '1.2rem 2rem',
              textAlign: 'left',
            }}
          >
            <p style={{ fontSize: '1.1rem', margin: 0, lineHeight: 1.8 }}>
              <strong style={{ color: '#0078e7' }}>L</strong> – Learning <br />
              <strong style={{ color: '#0078e7' }}>E</strong> – Engagement <br />
              <strong style={{ color: '#0078e7' }}>A</strong> – Activities <br />
              <strong style={{ color: '#0078e7' }}>R</strong> – Reusability <br />
              <strong style={{ color: '#0078e7' }}>N</strong> – Needs
            </p>
          </div>
        </div>

        <h2>About LEARNHub</h2>
        <p>
          <strong>LEARNHub</strong> is a recommendation system that suggests educational activities based on 
          selected classroom parameters. It supports teachers in finding computer science activities that fit 
          their available time, grade level, materials, and teaching goals.
        </p>

        <h2>About LEARNApp</h2>
        <p>
          <strong>LEARNApp</strong> is a digital teaching assistant that helps teachers integrate short, engaging
          computer science activities into everyday classroom settings.  
          It offers easy access to pre-curated learning materials that can be adapted to any class duration or topic.
        </p>
        <p>
          Powered by the <strong>LEARNHub recommendation algorithm</strong>, the app provides tailored activity
          suggestions based on selected input parameters — such as grade level, duration, topic, and available devices.
        </p>
        <p>
          Use this documentation to learn how to navigate the app, create recommendations, save favorites, and
          manage your account.
        </p>
      </main>
    </Layout>
  );
}
