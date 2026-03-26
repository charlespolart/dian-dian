import React from 'react';
import { View, StyleSheet, useWindowDimensions } from 'react-native';
import Svg, { Defs, Pattern, Circle, Rect } from 'react-native-svg';
import { COLORS } from '../lib/theme';

export default function DottedBackground({ children }: { children: React.ReactNode }) {
  const { width, height } = useWindowDimensions();

  return (
    <View style={styles.container}>
      <Svg style={StyleSheet.absoluteFill} width={width} height={height}>
        <Defs>
          <Pattern id="dots" x="0" y="0" width="32" height="32" patternUnits="userSpaceOnUse">
            <Circle cx="16" cy="16" r="2" fill={COLORS.bgDot} />
          </Pattern>
        </Defs>
        <Rect x="0" y="0" width="100%" height="100%" fill={COLORS.bg} />
        <Rect x="0" y="0" width="100%" height="100%" fill="url(#dots)" />
      </Svg>
      <View style={styles.content}>
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bg,
  },
  content: {
    flex: 1,
  },
});
