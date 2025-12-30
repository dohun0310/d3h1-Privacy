import LogoProps from "@/types/logo";

export default function Logo({
  size = 64,
  color = "var(--foreground)",
  className,
  ...props
}: LogoProps) {
  return (
    <svg 
      width={size * (29 / 51)}
      height={size}
      viewBox="0 0 29 51"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      {...props}
    >
      <path
        d="M0.00897648 0.0402696L28.7287 7.33987H28.6509V43.889L20.1492 7.33987H1.71052L10.3399 44.3663H29L12.7117 51H0V0L0.00897648 0.0402696Z"
        fill={color}
      />
    </svg>
  );
}