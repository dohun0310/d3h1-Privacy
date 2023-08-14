"use client"

import styled from "@emotion/styled";

const StyledHome = styled.main (() => `
  padding-top: 112px;

  & .contents-container {
    margin: 0 auto;
    max-width: 972px;
    width: 100%;
    min-height: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
    padding: 0 16px;
  }
`)

export default StyledHome;