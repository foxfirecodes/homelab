const WALLPAPERS = [
  "https://w.wallhaven.cc/full/rd/wallhaven-rdv81j.jpg",
  "https://w.wallhaven.cc/full/k8/wallhaven-k82ygd.jpg",
  "https://w.wallhaven.cc/full/ml/wallhaven-ml2ey9.png",
  "https://w.wallhaven.cc/full/ml/wallhaven-ml1km9.jpg",
  "https://w.wallhaven.cc/full/8g/wallhaven-8gkg5j.png"
]

document.documentElement.style.setProperty('--page-background', `url(${WALLPAPERS[Math.floor(Math.random() * WALLPAPERS.length)]})`)
