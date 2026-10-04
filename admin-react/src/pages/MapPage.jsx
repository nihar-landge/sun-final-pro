import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import api, { unwrap } from '../api/client';
import { StatusChip } from '../components/StatusChip';
import 'leaflet/dist/leaflet.css';

const CENTER = [18.5204, 73.8567]; // Pune

// Default marker icons break under bundlers — point them at the CDN copy.
const pin = (color) => L.divIcon({
  className: 'pin',
  html: `<span style="background:${color}"></span>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9],
});

const PIN_COLORS = { OPEN: '#f59e0b', IN_PROGRESS: '#3b82f6', RESOLVED: '#10b981' };

/** All geo-tagged reports on one OpenStreetMap view. */
export default function MapPage() {
  const [reports, setReports] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    unwrap(api.get('/feedback', { params: { size: 100 } }))
      .then((data) => {
        setReports((data.content || []).filter((r) => r.latitude != null));
      })
      .catch((e) => setError(e.response?.data?.message || e.message));
  }, []);

  return (
    <div>
      <h1>Map</h1>
      {error && <p className="error">{error}</p>}
      <div className="legend">
        {Object.entries(PIN_COLORS).map(([status, color]) => (
          <span key={status}><i style={{ background: color }} /> {status}</span>
        ))}
        <span className="muted">{reports.length} pinned reports</span>
      </div>
      <MapContainer center={CENTER} zoom={12} className="map">
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {reports.map((report) => (
          <Marker
            key={report.id}
            position={[report.latitude, report.longitude]}
            icon={pin(PIN_COLORS[report.status] || '#9ca3af')}
          >
            <Popup>
              <strong>#{report.id} — {report.title}</strong>
              <div><StatusChip status={report.status} /></div>
              <div className="muted">{report.category} · ▲ {report.upvotes}</div>
            </Popup>
          </Marker>
        ))}
        <Recenter reports={reports} />
      </MapContainer>
    </div>
  );
}

/** Fit the view to the reports once they arrive. */
function Recenter({ reports }) {
  const map = useMap();
  useEffect(() => {
    if (reports.length > 0) {
      map.fitBounds(
        reports.map((r) => [r.latitude, r.longitude]),
        { padding: [40, 40], maxZoom: 14 },
      );
    }
  }, [reports, map]);
  return null;
}
