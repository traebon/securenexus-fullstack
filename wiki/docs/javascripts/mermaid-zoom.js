// Make Mermaid diagrams zoomable with custom modal
document.addEventListener('DOMContentLoaded', function() {
    // Create modal overlay
    const modal = document.createElement('div');
    modal.id = 'diagram-modal';
    modal.style.cssText = `
        display: none;
        position: fixed;
        z-index: 9999;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.95);
        overflow: auto;
        cursor: zoom-out;
    `;

    const modalContent = document.createElement('div');
    modalContent.style.cssText = `
        position: relative;
        margin: 2% auto;
        width: 95%;
        max-width: 1400px;
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 90vh;
    `;

    const closeBtn = document.createElement('span');
    closeBtn.innerHTML = '&times;';
    closeBtn.style.cssText = `
        position: fixed;
        top: 20px;
        right: 35px;
        color: #f1f1f1;
        font-size: 50px;
        font-weight: bold;
        cursor: pointer;
        z-index: 10000;
        transition: 0.3s;
    `;
    closeBtn.onmouseover = () => closeBtn.style.color = '#3b82f6';
    closeBtn.onmouseout = () => closeBtn.style.color = '#f1f1f1';

    const diagramContainer = document.createElement('div');
    diagramContainer.id = 'modal-diagram-container';
    diagramContainer.style.cssText = `
        width: 100%;
        background: white;
        padding: 2rem;
        border-radius: 8px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.5);
        overflow: auto;
    `;

    modalContent.appendChild(diagramContainer);
    modal.appendChild(closeBtn);
    modal.appendChild(modalContent);
    document.body.appendChild(modal);

    // Close modal when clicking outside or on X
    modal.onclick = function(e) {
        if (e.target === modal || e.target === closeBtn) {
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';
        }
    };

    // Close on ESC key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && modal.style.display === 'block') {
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';
        }
    });

    // Wait for Mermaid to render
    setTimeout(function() {
        const mermaidDiagrams = document.querySelectorAll('.mermaid');

        mermaidDiagrams.forEach(function(diagram, index) {
            // Skip if already wrapped
            if (diagram.dataset.zoomable) return;
            diagram.dataset.zoomable = 'true';

            const svg = diagram.querySelector('svg');
            if (!svg) return;

            // Make clickable
            diagram.style.cursor = 'zoom-in';
            diagram.style.position = 'relative';

            // Add click handler
            diagram.onclick = function() {
                // Clone the SVG
                const clone = svg.cloneNode(true);

                // Make it large
                clone.style.width = '100%';
                clone.style.height = 'auto';
                clone.style.maxWidth = 'none';
                clone.removeAttribute('width');
                clone.removeAttribute('height');
                clone.setAttribute('preserveAspectRatio', 'xMidYMid meet');

                // Clear and add to modal
                diagramContainer.innerHTML = '';
                diagramContainer.appendChild(clone);

                // Show modal
                modal.style.display = 'block';
                document.body.style.overflow = 'hidden';

                // Prevent click propagation
                return false;
            };

            // Add zoom hint on hover
            diagram.addEventListener('mouseenter', function() {
                if (!diagram.querySelector('.zoom-hint')) {
                    const hint = document.createElement('div');
                    hint.className = 'zoom-hint';
                    hint.innerHTML = '🔍 Click to enlarge';
                    hint.style.cssText = `
                        position: absolute;
                        top: 10px;
                        right: 10px;
                        background: rgba(59, 130, 246, 0.95);
                        color: white;
                        padding: 6px 12px;
                        border-radius: 6px;
                        font-size: 0.85rem;
                        font-weight: 600;
                        z-index: 100;
                        pointer-events: none;
                        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
                    `;
                    diagram.appendChild(hint);
                }
            });

            diagram.addEventListener('mouseleave', function() {
                const hint = diagram.querySelector('.zoom-hint');
                if (hint) hint.remove();
            });
        });
    }, 1500);
});
