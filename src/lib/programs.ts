export const PROGRAMS = [
  "ბუღალტრული აღრიცხვა",
  "Front-end დეველოპმენტი",
  "აღმზრდელი",
  "ქსელები და სისტემები",
  "გრაფიკული დიზაინი",
] as const;
export type Program = (typeof PROGRAMS)[number];
