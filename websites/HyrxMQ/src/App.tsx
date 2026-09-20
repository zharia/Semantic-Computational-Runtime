import { Navbar } from './components/Navbar'
import { Hero } from './components/Hero'
import { Family } from './components/Family'
import { About } from './components/About'
import { Architecture } from './components/Architecture'
import { Features } from './components/Features'
import { Benefits } from './components/Benefits'
import { Comparison } from './components/Comparison'
import { Performance } from './components/Performance'
import { ByteMoney } from './components/ByteMoney'
import { Technology } from './components/Technology'
import { Industries } from './components/Industries'
import { CallToAction } from './components/CallToAction'
import { Footer } from './components/Footer'

export default function App() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <Family />
        <About />
        <Architecture />
        <Features />
        <Benefits />
        <Comparison />
        <Performance />
        <ByteMoney />
        <Technology />
        <Industries />
        <CallToAction />
      </main>
      <Footer />
    </>
  )
}
