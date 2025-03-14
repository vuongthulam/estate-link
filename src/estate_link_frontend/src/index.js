import { estate_link_backend } from "../../declarations/estate_link_backend";

document.querySelector(".search-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const button = e.target.querySelector("button");
  const searchInput = document.getElementById("search");
  const propertiesGrid = document.getElementById("greeting");

  const searchTerm = searchInput.value.toString();
  button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Searching...';
  button.setAttribute("disabled", true);

  try {
    // const properties = await estate_link_backend.search(searchTerm);

    propertiesGrid.innerHTML = `
            <div class="property-card">
                <img src="property-placeholder.jpg" alt="Property" class="property-image">
                <div class="property-details">
                    <h3 class="property-title">Modern ${searchTerm} Apartment</h3>
                    <div class="property-features">
                        <span><i class="fas fa-bed"></i> 3 beds</span>
                        <span><i class="fas fa-bath"></i> 2 baths</span>
                        <span><i class="fas fa-ruler-combined"></i> 1500 sqft</span>
                    </div>
                    <p class="property-price">$500,000</p>
                </div>
            </div>
        `;
  } catch (error) {
    propertiesGrid.innerHTML = `<p class="error-message">No properties found matching "${searchTerm}"</p>`;
  }

  button.innerHTML = '<i class="fas fa-search"></i> Search Properties';
  button.removeAttribute("disabled");
});
