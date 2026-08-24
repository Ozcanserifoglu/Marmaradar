import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Home from './pages/Home'
import ResetPassword from './pages/ResetPassword'
import Changelog from './pages/Changelog'
import Privacy from './pages/Privacy'
import TermsOfUse from './pages/TermsOfUse'
import './App.css'

export default function App() {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <div className="noise" aria-hidden="true" />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="/changelog" element={<Changelog />} />
          <Route path="/gizlilik" element={<Privacy />} />
          <Route path="/kullanim-sartlari" element={<TermsOfUse />} />
        </Routes>
      </div>
    </BrowserRouter>
  )
}
