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
        {/* Animated gradient orbs */}
        <div
          style={{
            position: 'absolute',
            width: '800px',
            height: '800px',
            background: 'radial-gradient(circle, rgba(0,82,255,0.4) 0%, transparent 70%)',
            borderRadius: '50%',
            top: '100px',
            left: '140px',
          }}
        />
        <div
          style={{
            position: 'absolute',
            width: '600px',
            height: '600px',
            background: 'radial-gradient(circle, rgba(124,58,237,0.3) 0%, transparent 70%)',
            borderRadius: '50%',
            bottom: '200px',
            right: '140px',
          }}
        />
        <div
          style={{
            position: 'absolute',
            width: '500px',
            height: '500px',
            background: 'radial-gradient(circle, rgba(236,72,153,0.25) 0%, transparent 70%)',
            borderRadius: '50%',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
          }}
        />

        {/* Main icon with gradient border */}
        <div
          style={{
            width: '450px',
            height: '450px',
            background: 'linear-gradient(135deg, #0052FF 0%, #7C3AED 50%, #EC4899 100%)',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 100,
            boxShadow: '0 0 100px rgba(0, 82, 255, 0.6)',
          }}
        >
          <div
            style={{
              width: '420px',
              height: '420px',
              background: '#0F172A',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 250,
            }}
          >
            🎨
          </div>
        </div>

        {/* Text */}
        <div
          style={{
            fontSize: 120,
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
            fontSize: 50,
            color: 'rgba(241,245,249,0.8)',
            textAlign: 'center',
          }}
        >
          Daily Collective Color NFT
        </div>
      </div>
    ),
    {
      width: 1080,
      height: 1920,
    }
  );
}
