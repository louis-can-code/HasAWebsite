import titleSVG from "../../static/has_a_website.svg";

class HasAWebsiteTitle extends HTMLElement {
    // Provides Encapsulation, may remove later
    private root: ShadowRoot;

    constructor() {
        super();
        console.log(titleSVG)
        this.root = this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        this.render()
    }

    private render() {
        this.root.innerHTML = titleSVG
    }
}

customElements.define("has-a-website-title", HasAWebsiteTitle)