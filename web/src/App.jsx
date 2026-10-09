import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { MotionConfig } from 'motion/react'
import Home from './pages/Home'
import ResetPassword from './pages/ResetPassword'
import DeleteAccount from './pages/DeleteAccount'
import Changelog from './pages/Changelog'
import Privacy from './pages/Privacy'
import TermsOfUse from './pages/TermsOfUse'
import './App.css'

export default function App() {
  return (
    <MotionConfig reducedMotion="user">
      <BrowserRouter>
        <div className="app-shell">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/reset-password" element={<ResetPassword />} />
            <Route path="/hesap-sil" element={<DeleteAccount />} />
            <Route path="/changelog" element={<Changelog />} />
            <Route path="/gizlilik" element={<Privacy />} />
            <Route path="/kullanim-sartlari" element={<TermsOfUse />} />
          </Routes>
        </div>
      </BrowserRouter>
    </MotionConfig>
  )
}
