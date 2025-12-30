import Header from "@/components/Header";

export default function Home() {
  return (
    <>
      <Header />
      <main className="flex flex-col gap-4
        mx-auto my-24 px-4 max-w-[1325px]"
      >
        <h1 className="text-2xl font-bold lg:text-3xl">
          Privacy Policy
        </h1>

        <p className="text-sm lg:text-base">
          d3h1이(가) 취급하는 모든 개인정보는 개인정보보호법 등 관련 법령상의 개인정보보호 규정을 준수하여 이용자의 개인정보 보호 및 권익을 보호하고 개인정보와 관련한 이용자의 고충을 원활하게 처리할 수 있도록 다음과 같은 처리방침을 두고 있습니다.
        </p>

        <h3 className="text-lg lg:text-xl font-bold">
          1. 개인정보의 처리 목적
        </h3>

        <p className="text-sm lg:text-base">
          - 2023.01.01 시점을 기준으로 현재 사용자의 개인정보를 수집하지 않고 있습니다.
        </p>

        <h3 className="text-lg lg:text-xl font-bold">
          2. 개인정보의 처리 및 보유 기간
        </h3>

        <p className="text-sm lg:text-base">
          - 2023.01.01 시점을 기준으로 현재 사용자의 개인정보를 수집하지 않고 있습니다.
        </p>

        <h3 className="text-lg lg:text-xl font-bold">
          3. 개인정보의 파기 절차
        </h3>

        <p className="text-sm lg:text-base">
          - 2023.01.01 시점을 기준으로 현재 사용자의 개인정보를 수집하지 않고 있습니다.
        </p>

        <h3 className="text-lg lg:text-xl font-bold">
          4. 개인정보 보호 책임자
        </h3>

        <p className="text-sm lg:text-base">부서명 : d3h1</p>
        <p className="text-sm lg:text-base">성명 : 김도훈</p>
        <p className="text-sm lg:text-base">직책 : 개발담당자</p>
        <p className="text-sm lg:text-base">이메일 : d3h1@d3h1.com</p>

        <p className="text-sm lg:text-base">
          모든 사용자께서는 개인정보보호 관련 문의를 책임자에게 언제든지 하실 수 있으시며, 정확한 답변을 드리도록 할 것 입니다.
        </p>
      </main>
    </>
  )
}
