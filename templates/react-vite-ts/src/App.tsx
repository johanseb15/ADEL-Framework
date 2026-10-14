import { useState } from 'react'

export default function App() {
  const [count, setCount] = useState(0)
  return <main><h1>New ADEL project</h1><p>React, Vite and TypeScript are ready.</p><button onClick={() => setCount(value => value + 1)}>Count: {count}</button></main>
}
