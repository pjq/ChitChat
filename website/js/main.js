
const carousel = document.querySelector('.carousel');
const slides = carousel.querySelector('.slides');

function cloneFirstSlide() {
  const firstSlide = slides.querySelector('img:first-child');
  const clonedSlide = firstSlide.cloneNode(true);
  slides.appendChild(clonedSlide);
}

cloneFirstSlide();
