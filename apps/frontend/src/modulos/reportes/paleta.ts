/**
 * Paleta de las gráficas. Recharts necesita valores de color en JS, así que viven aquí
 * y no en @theme. El primero es marca-700; los demás se distinguen entre sí y tienen
 * al menos 3:1 de contraste sobre blanco.
 */
export const COLOR_MARCA = '#0f766e'; // marca-700
export const COLOR_MARCA_SUAVE = '#ccfbf1'; // marca-100

export const PALETA_CATEGORIAS = [
  COLOR_MARCA,
  '#2563eb', // azul
  '#d97706', // ámbar
  '#be185d', // magenta
  '#7c3aed', // violeta
  '#4d7c0f', // oliva
  '#155e75', // petróleo
  '#475569', // slate
] as const;
