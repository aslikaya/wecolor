import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET() {
  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#0F172A',
          position: 'relative',
        }}
      >
        {/* Gradient orbs background */}
        <div
          style={{
            position: 'absolute',
            width: '600px',
            height: '600px',
            background: 'radial-gradient(circle, rgba(0,82,255,0.3) 0%, transparent 70%)',
            borderRadius: '50%',
            top: '-100px',
            left: '-100px',
          }}
        />
        <div
          style={{
            position: 'absolute',
            width: '500px',
            height: '500px',
            background: 'radial-gradient(circle, rgba(124,58,237,0.25) 0%, transparent 70%)',
            borderRadius: '50%',
            bottom: '-150px',
            right: '-150px',
          }}
        />
        <div
          style={{
            position: 'absolute',
            width: '400px',
            height: '400px',
            background: 'radial-gradient(circle, rgba(236,72,153,0.2) 0%, transparent 70%)',
            borderRadius: '50%',
            top: '50%',
            right: '10%',
          }}
        />

        {/* Content */}
        <div
          style={{
            display: 'flex',
            fontSize: 140,
            marginBottom: 40,
          }}
        >
          🎨
        </div>
        <div
          style={{
            display: 'flex',
            fontSize: 90,
            fontWeight: 'bold',
            background: 'linear-gradient(135deg, #0052FF 0%, #7C3AED 50%, #EC4899 100%)',
            backgroundClip: 'text',
            color: 'transparent',
            marginBottom: 30,
          }}
        >
          WeColor
        </div>
        <div
          style={{
            display: 'flex',
            fontSize: 36,
            color: 'rgba(241,245,249,0.9)',
            textAlign: 'center',
          }}
        >
          Daily Collective Color NFT on Base
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  );
}
