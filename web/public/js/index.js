$().ready(function() {
    $('.slick-carousel').slick({
        // Altura de las imágenes común para todas
        centerMode: true, // Modo centrado
        dots: true, // Puntos de navegación
        infinite: true, // Bucle infinito de las imágenes (cuando termina la última, vuelve a la primera)
        speed: 300, // Velocidad de transición
        autoplay: true, // Autoplay
        slidesToShow: 4, // Películas a mostrar en el carrusel
        slidesToScroll: 1, // Desplazamiento de las películas
        responsive: [
            {
                breakpoint: 1024,
                settings: {
                    slidesToShow: 3,
                    infinite: true,
                    dots: true
                }
            },
            {
                breakpoint: 600,
                settings: {
                    slidesToShow: 2
                }
            },
            {
                breakpoint: 480,
                settings: {
                    slidesToShow: 1
                }
            }
        ]
    });
});

document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('billboardButton').addEventListener('click', function() {
        window.location.href = "billboard.html";
    });
});