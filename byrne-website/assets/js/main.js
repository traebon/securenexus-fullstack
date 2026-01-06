// Byrne Accounting - Main JavaScript

// ============================================
// Mobile Menu Toggle
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const mobileMenuToggle = document.getElementById('mobileMenuToggle');
    const navMenu = document.getElementById('navMenu');

    if (mobileMenuToggle && navMenu) {
        mobileMenuToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');

            // Animate hamburger icon
            const spans = this.querySelectorAll('span');
            if (navMenu.classList.contains('active')) {
                spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
                spans[1].style.opacity = '0';
                spans[2].style.transform = 'rotate(-45deg) translate(7px, -6px)';
            } else {
                spans.forEach(span => {
                    span.style.transform = '';
                    span.style.opacity = '';
                });
            }
        });

        // Close mobile menu when clicking on a link
        navMenu.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', function() {
                navMenu.classList.remove('active');
                const spans = mobileMenuToggle.querySelectorAll('span');
                spans.forEach(span => {
                    span.style.transform = '';
                    span.style.opacity = '';
                });
            });
        });

        // Close mobile menu when clicking outside
        document.addEventListener('click', function(event) {
            if (!navMenu.contains(event.target) && !mobileMenuToggle.contains(event.target)) {
                navMenu.classList.remove('active');
                const spans = mobileMenuToggle.querySelectorAll('span');
                spans.forEach(span => {
                    span.style.transform = '';
                    span.style.opacity = '';
                });
            }
        });
    }
});

// ============================================
// Smooth Scrolling for Anchor Links
// ============================================
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href !== '#') {
            e.preventDefault();
            const target = document.querySelector(href);
            if (target) {
                // Account for fixed navbar height
                const navbarHeight = document.querySelector('.navbar').offsetHeight;
                const targetPosition = target.offsetTop - navbarHeight;

                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        }
    });
});

// ============================================
// Navbar Scroll Effect
// ============================================
let lastScroll = 0;
const navbar = document.getElementById('navbar');

window.addEventListener('scroll', function() {
    const currentScroll = window.pageYOffset;

    // Add shadow on scroll
    if (currentScroll > 50) {
        navbar.style.boxShadow = '0 10px 15px -3px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
    }

    lastScroll = currentScroll;
});

// ============================================
// Contact Form Handling
// ============================================
const contactForm = document.getElementById('contactForm');

if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();

        // Get form data
        const formData = {
            name: document.getElementById('name').value,
            email: document.getElementById('email').value,
            phone: document.getElementById('phone') ? document.getElementById('phone').value : '',
            company: document.getElementById('company') ? document.getElementById('company').value : '',
            service: document.getElementById('service') ? document.getElementById('service').value : '',
            message: document.getElementById('message').value
        };

        // Show loading state
        const submitButton = this.querySelector('button[type="submit"]');
        const originalButtonText = submitButton.innerHTML;
        submitButton.disabled = true;
        submitButton.innerHTML = '<span>Sending...</span>';

        // Simulate form submission (replace with actual backend call)
        setTimeout(() => {
            // Reset form
            contactForm.reset();

            // Show success message
            submitButton.innerHTML = '<span>✓ Message Sent!</span>';
            submitButton.style.background = 'linear-gradient(135deg, #0d9488 0%, #14b8a6 100%)';

            // Reset button after 3 seconds
            setTimeout(() => {
                submitButton.disabled = false;
                submitButton.innerHTML = originalButtonText;
                submitButton.style.background = '';
            }, 3000);

            // Log form data (remove this in production)
            console.log('Form submitted:', formData);

            // In production, send to backend:
            /*
            fetch('/api/contact', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData)
            })
            .then(response => response.json())
            .then(data => {
                // Handle success
                submitButton.innerHTML = '<span>✓ Message Sent!</span>';
            })
            .catch(error => {
                // Handle error
                console.error('Error:', error);
                submitButton.innerHTML = '<span>✗ Error. Please try again.</span>';
            })
            .finally(() => {
                setTimeout(() => {
                    submitButton.disabled = false;
                    submitButton.innerHTML = originalButtonText;
                    submitButton.style.background = '';
                }, 3000);
            });
            */
        }, 1500);
    });
}

// ============================================
// Intersection Observer for Animations
// ============================================
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements with animation class
document.addEventListener('DOMContentLoaded', function() {
    // Add fade-in animation to service cards, testimonials, etc.
    const animatedElements = document.querySelectorAll('.service-card, .testimonial-card, .about-card, .why-feature');

    animatedElements.forEach((el, index) => {
        // Set initial state
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        el.style.transitionDelay = `${index * 0.1}s`;

        // Observe
        observer.observe(el);
    });
});

// ============================================
// Utility Functions
// ============================================

// Format phone numbers as user types
const phoneInput = document.getElementById('phone');
if (phoneInput) {
    phoneInput.addEventListener('input', function(e) {
        let value = e.target.value.replace(/\D/g, '');
        if (value.length > 0) {
            if (value.length <= 3) {
                value = `(${value}`;
            } else if (value.length <= 6) {
                value = `(${value.slice(0, 3)}) ${value.slice(3)}`;
            } else {
                value = `(${value.slice(0, 3)}) ${value.slice(3, 6)}-${value.slice(6, 10)}`;
            }
        }
        e.target.value = value;
    });
}

// Add active state to current nav link based on scroll position
window.addEventListener('scroll', function() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');

    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop - 100;
        const sectionHeight = section.offsetHeight;
        if (window.pageYOffset >= sectionTop && window.pageYOffset < sectionTop + sectionHeight) {
            current = section.getAttribute('id');
        }
    });

    navLinks.forEach(link => {
        link.style.color = '';
        link.style.fontWeight = '';
        if (link.getAttribute('href') === `#${current}`) {
            link.style.color = '#1e3a8a';
            link.style.fontWeight = '700';
        }
    });
});

// ============================================
// Console Message
// ============================================
console.log('%c Byrne Accounting ', 'background: #1e3a8a; color: white; font-size: 16px; font-weight: bold; padding: 10px 20px; border-radius: 5px;');
console.log('%c Professional Financial Services with Modern Technology ', 'color: #0d9488; font-size: 12px; padding: 5px 0;');
console.log('%c Powered by SecureNexus Infrastructure ', 'color: #6b7280; font-size: 10px;');
