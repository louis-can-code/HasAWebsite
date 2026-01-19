import titleSVG from "../../static/has_a_website.svg";

type SpinDirection = "clockwise" | "anticlockwise";

class HasAWebsiteTitle extends HTMLElement {
	// Provides Encapsulation, may remove later
	private root: ShadowRoot;
	private cogAnimations: CogAnimation[];

	constructor() {
		super();
		this.root = this.attachShadow({ mode: "open" });
	}

	connectedCallback() {
		this.render();
		this.setupAnimations();
	}

	private render() {
		this.root.innerHTML = titleSVG;
	}

	private setupAnimations() {
		const cogs: [SpinDirection, string[]][] = [
			[
				"clockwise",
				[
					"cog-h-top",
					"cog-h-bottom",
					"cog-a1-top",
					"cog-s1-top",
					"cog-a2-top",
					"cog-a2-bottom",
					"cog-w",
					"cog-e1-top",
					"cog-e1-bottom",
					"cog-b-top-small",
					"cog-b-middle",
					"cog-s2-top",
					"cog-s2-bottom",
					"cog-i-middle",
					"cog-t-top",
					"cog-t-bottom",
				],
			],
			[
				"anticlockwise",
				[
					"cog-a1-middle",
					"cog-a1-s1",
					"cog-a2-middle",
					"cog-w-e1",
					"cog-b-bottom",
					"cog-b-top-big",
					"cog-b-s2",
					"cog-i-bottom",
					"cog-i-t",
					"cog-e2",
				],
			],
		];

		const svg = this.root.querySelector<SVGSVGElement>("svg");

		this.cogAnimations = cogs.flatMap(([direction, ids]) =>
			ids.map(
				(id) =>
					new CogAnimation(
						svg.querySelector<SVGGElement>(`#${id}`),
						direction,
						20_000,
					),
			),
		);

		this.cogAnimations.forEach((cog) => {
			cog.start();
		});

		this.addEventListener("mouseenter", (e) => {
			this.cogAnimations.forEach((cog) => {
				cog.changeSpeed(6_000);
			});
		});

		this.addEventListener("mouseleave", (e) => {
			this.cogAnimations.forEach((cog) => {
				cog.changeSpeed(20_000);
			});
		});
	}
}

class CogAnimation {
	//private isRunning = false;
	private animationId: number | null = null;

	constructor(cog: SVGGElement, direction: SpinDirection, duration: number) {
		this.cog = cog;
		this.direction = direction === "clockwise" ? 1 : -1;
		this.time = {
			start: performance.now(),
			duration: duration,
		};
		this.centre = this.findCenter(cog);
	}

	public start() {
		//this.isRunning = true;
		this.animationId = requestAnimationFrame(this.tick);
	}

	public stop() {
		//this.isRunning = false;
		if (this.animationId !== null) {
			window.cancelAnimationFrame(this.animationId);
			this.animationId = null;
		}
	}

	public changeSpeed(newDuration: number) {
		const now = performance.now();
		const elapsed = now - this.time.start;
		const progress = (elapsed % this.time.duration) / this.time.duration;

		this.time.start = now - newDuration * progress;
		this.time.duration = newDuration;
	}

	private findCenter(cog: SVGGElement) {
		const box = cog.getBBox();
		return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
	}

	private tick = (now: number) => {
		const elapsedTime = now - this.time.start;
		const progress =
			(elapsedTime % this.time.duration) / this.time.duration;

		this.cog.style.transformOrigin = `${this.centre.x}px ${this.centre.y}px`;
		this.cog.style.transform = `rotate(${360 * progress * this.direction}deg)`;

		window.requestAnimationFrame(this.tick);
	};
}

customElements.define("has-a-website-title", HasAWebsiteTitle);
