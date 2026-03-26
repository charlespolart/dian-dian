import { useEffect } from 'react';
import { Platform } from 'react-native';

// On web, require() returns the URL string directly via the bundler
const cursorSrc = require('../../assets/cursor.gif') as string | { default: string; uri?: string };

export default function CustomCursor() {
  useEffect(() => {
    if (Platform.OS !== 'web') return;

    const src = typeof cursorSrc === 'string'
      ? cursorSrc
      : (cursorSrc as any)?.default ?? (cursorSrc as any)?.uri ?? '';
    if (!src) return;

    const img = document.createElement('img');
    img.src = src;
    Object.assign(img.style, {
      position: 'fixed',
      width: '36px',
      height: '36px',
      pointerEvents: 'none',
      zIndex: '99999',
      transform: 'translate(-50%, -50%)',
      display: 'none',
    });
    document.body.appendChild(img);

    // Hide default cursor
    const style = document.createElement('style');
    style.textContent = '* { cursor: none !important; }';
    document.head.appendChild(style);

    let x = 0, y = 0;
    const update = () => {
      const vv = window.visualViewport;
      if (vv) {
        const scale = vv.scale;
        img.style.left = (x - vv.offsetLeft) / scale + 'px';
        img.style.top = (y - vv.offsetTop) / scale + 'px';
        img.style.width = 36 / scale + 'px';
        img.style.height = 36 / scale + 'px';
      } else {
        img.style.left = x + 'px';
        img.style.top = y + 'px';
      }
    };

    const onMouseMove = (e: MouseEvent) => {
      x = e.clientX;
      y = e.clientY;
      img.style.display = 'block';
      update();
    };

    const onTouchStart = (e: TouchEvent) => {
      x = e.touches[0].clientX;
      y = e.touches[0].clientY;
      img.style.display = 'block';
      requestAnimationFrame(update);
    };

    const onTouchMove = (e: TouchEvent) => {
      x = e.touches[0].clientX;
      y = e.touches[0].clientY;
      update();
    };

    // Reposition on viewport zoom/scroll
    const onViewportChange = () => update();
    window.visualViewport?.addEventListener('resize', onViewportChange);
    window.visualViewport?.addEventListener('scroll', onViewportChange);

    document.addEventListener('mousemove', onMouseMove, { passive: true });
    document.addEventListener('touchstart', onTouchStart, { passive: true });
    document.addEventListener('touchmove', onTouchMove, { passive: true });

    return () => {
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('touchstart', onTouchStart);
      document.removeEventListener('touchmove', onTouchMove);
      window.visualViewport?.removeEventListener('resize', onViewportChange);
      window.visualViewport?.removeEventListener('scroll', onViewportChange);
      img.remove();
      style.remove();
    };
  }, []);

  return null;
}
