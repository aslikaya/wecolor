import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: '#0F172A',
          position: 'relative',
        }}
      >
        {/* Gradient orbs */}
        <div
          style={{
            position: 'absolute',
            width: '400px',
            height: '400px',
            background: 'radial-gradient(circle, rgba(0,82,255,0.4) 0%, transparent 70%)',
            borderRadius: '50%',
            top: '56px',
            left: '56px',
          }}
        />
        <div
          style={{
            position: 'absolute',
            width: '300px',
            height: '300px',
            background: 'radial-gradient(circle, rgba(124,58,237,0.3) 0%, transparent 70%)',
            borderRadius: '50%',
            bottom: '106px',
            right: '106px',
          }}
        />

        {/* Main icon circle with gradient border */}
        <div
          style={{
            width: '380px',
            height: '380px',
            background: 'linear-gradient(135deg, #0052FF 0%, #7C3AED 50%, #EC4899 100%)',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 0 60px rgba(0, 82, 255, 0.5)',
          }}
        >
          <div
            style={{
              width: '360px',
              height: '360px',
              background: '#0F172A',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 200,
            }}
          >
            🎨
          </div>
        </div>
      </div>
    ),
    {
      width: 512,
      height: 512,
    }
  );
}
