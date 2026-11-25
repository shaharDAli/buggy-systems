import { useState } from 'react'

const stages = [
  { title: 'Incoming', action: 'Accept order' },
  { title: 'Preparing', action: 'Mark nearly ready' },
  { title: 'Nearly ready', action: 'Mark ready for pickup' },
  { title: 'Ready for pickup', action: '' },
]

const sampleOrders = [
  { id: 1042, items: ['2 × Masala dosa', '1 × Filter coffee'], stage: 0 },
  { id: 1041, items: ['1 × Idli with sambar'], stage: 1 },
]

export default function App() {
  const [orders, setOrders] = useState(sampleOrders)
  const [message, setMessage] = useState('')

  function advanceOrder(id: number, stage: number) {
    setOrders(current => current.map(order =>
      order.id === id && order.stage === stage ? { ...order, stage: stage + 1 } : order
    ))
    setMessage(`Order #${id} moved to ${stages[stage + 1].title.toLowerCase()}.`)
  }

  return (
    <>
      <header><div className="masthead"><strong>Buggy Portal</strong><span>Green Tiffin</span></div></header>
      <main>
        <h1>Orders</h1>
        <div className="board">
          {stages.map(({ title, action }, index) => {
            const queue = orders.filter(order => order.stage === index)
            return (
              <section key={title} aria-label={title}>
                <h2>{title} <span className="count">{queue.length}</span></h2>
                {queue.length === 0 && <p className="empty">No orders</p>}
                {queue.map(order => (
                  <article key={order.id}>
                    <h3>#{order.id}</h3>
                    <ul>{order.items.map(item => <li key={item}>{item}</li>)}</ul>
                    {action && <button onClick={() => advanceOrder(order.id, index)}>{action}</button>}
                  </article>
                ))}
              </section>
            )
          })}
        </div>
        <p className="status" role="status">{message}</p>
      </main>
    </>
  )
}
