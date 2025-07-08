// Fade in footer when it enters the viewport
function fadeInFooterOnScroll() {
  const footer = document.querySelector('.footer');
  if (!footer) return;
  const rect = footer.getBoundingClientRect();
  if (rect.top < window.innerHeight - 50) {
    footer.classList.add('footer-fade-in');
    window.removeEventListener('scroll', fadeInFooterOnScroll);
  }
}
window.addEventListener('scroll', fadeInFooterOnScroll);
window.addEventListener('DOMContentLoaded', fadeInFooterOnScroll);
