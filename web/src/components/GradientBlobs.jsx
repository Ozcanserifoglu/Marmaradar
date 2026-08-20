import './GradientBlobs.css'

export default function GradientBlobs({ subtle = false }) {
  return (
    <div className={`blobs${subtle ? ' blobs-subtle' : ''}`} aria-hidden="true">
      <div className="blob blob-1" />
      <div className="blob blob-2" />
      <div className="blob blob-3" />
    </div>
  )
}
