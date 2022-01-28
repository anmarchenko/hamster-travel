defmodule HamsterTravelWeb.Icons do
  @moduledoc """
  Icons for live views
  """
  use HamsterTravelWeb, :component

  def home(assigns) do
    ~H"""
      <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="18" height="18" class={classes(assigns)}>
        <path d="M7.5.5l.325-.38a.5.5 0 00-.65 0L7.5.5zm-7 6l-.325-.38L0 6.27v.23h.5zm5 8v.5a.5.5 0 00.5-.5h-.5zm4 0H9a.5.5 0 00.5.5v-.5zm5-8h.5v-.23l-.175-.15-.325.38zM1.5 15h4v-1h-4v1zm13.325-8.88l-7-6-.65.76 7 6 .65-.76zm-7.65-6l-7 6 .65.76 7-6-.65-.76zM6 14.5v-3H5v3h1zm3-3v3h1v-3H9zm.5 3.5h4v-1h-4v1zm5.5-1.5v-7h-1v7h1zm-15-7v7h1v-7H0zM7.5 10A1.5 1.5 0 019 11.5h1A2.5 2.5 0 007.5 9v1zm0-1A2.5 2.5 0 005 11.5h1A1.5 1.5 0 017.5 10V9zm6 6a1.5 1.5 0 001.5-1.5h-1a.5.5 0 01-.5.5v1zm-12-1a.5.5 0 01-.5-.5H0A1.5 1.5 0 001.5 15v-1z" fill="currentColor"></path>
      </svg>
    """
  end

  def pen(assigns) do
    ~H"""
      <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="18" height="18" class={classes(assigns)}>
        <path d="M2.5.5V0H2v.5h.5zm10 0h.5V0h-.5v.5zM4.947 4.724a.5.5 0 00-.894-.448l.894.448zM2.5 8.494l-.447-.223-.146.293.21.251.383-.32zm5 5.997l-.384.32a.5.5 0 00.769 0l-.385-.32zm5-5.996l.384.32.21-.251-.146-.293-.447.224zm-1.553-4.219a.5.5 0 00-.894.448l.894-.448zM8 9.494v-.5H7v.5h1zm-.5-4.497A4.498 4.498 0 013 .5H2a5.498 5.498 0 005.5 5.497v-1zM2.5 1h10V0h-10v1zM12 .5a4.498 4.498 0 01-4.5 4.497v1c3.038 0 5.5-2.46 5.5-5.497h-1zM4.053 4.276l-2 3.995.895.448 2-3.995-.895-.448zM2.116 8.815l5 5.996.769-.64-5-5.996-.769.64zm5.768 5.996l5-5.996-.768-.64-5 5.996.769.64zm5.064-6.54l-2-3.995-.895.448 2 3.995.895-.448zM8 14.49V9.494H7v4.997h1z" fill="currentColor"></path>
      </svg>
    """
  end

  def money_stack(assigns) do
    ~H"""
    <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="15" height="15" class={classes(assigns)}>
    <path d="M0 12.5h15m-15 2h15M2.5 4V2.5H4m7 0h1.5V4m-10 3v1.5H4m7 0h1.5V7m-5 .5a2 2 0 110-4 2 2 0 010 4zm-6-7h12a1 1 0 011 1v8a1 1 0 01-1 1h-12a1 1 0 01-1-1v-8a1 1 0 011-1z" stroke="currentColor"></path>
    </svg>
    """
  end

  def calendar(assigns) do
    ~H"""
    <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="15" height="15" class={classes(assigns)}>
      <path d="M3.5 0v5m8-5v5m-10-2.5h12a1 1 0 011 1v10a1 1 0 01-1 1h-12a1 1 0 01-1-1v-10a1 1 0 011-1z" stroke="currentColor"></path>
    </svg>
    """
  end

  def user(assigns) do
    ~H"""
    <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="15" height="15" class={classes(assigns)}>
      <path clip-rule="evenodd" d="M10.5 3.498a2.999 2.999 0 01-3 2.998 2.999 2.999 0 113-2.998zm2 10.992h-10v-1.996a3 3 0 013-3h4a3 3 0 013 3v1.997z" stroke="currentColor" stroke-linecap="square"></path>
    </svg>
    """
  end

  def book(assigns) do
    ~H"""
    <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="15" height="15" class={classes(assigns)}>
      <path d="M1.5.5V0a.5.5 0 00-.5.5h.5zm0 13H1a.5.5 0 00.5.5v-.5zM4 0v15h1V0H4zM1.5 1h10V0h-10v1zM13 2.5v9h1v-9h-1zM11.5 13h-10v1h10v-1zm-9.5.5V.5H1v13h1zm11-2a1.5 1.5 0 01-1.5 1.5v1a2.5 2.5 0 002.5-2.5h-1zM11.5 1A1.5 1.5 0 0113 2.5h1A2.5 2.5 0 0011.5 0v1zM7 5h4V4H7v1z" fill="currentColor"></path>
    </svg>
    """
  end

  def note(assigns) do
    ~H"""
      <svg viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg" width="15" height="15" class={classes(assigns)}>
        <path d="M10.5 14.5H10a.5.5 0 00.854.354L10.5 14.5zm0-4V10a.5.5 0 00-.5.5h.5zm4 0l.354.354A.5.5 0 0014.5 10v.5zM1.5 1h12V0h-12v1zM1 13.5v-12H0v12h1zm13-12v8.586h1V1.5h-1zM10.086 14H1.5v1h8.586v-1zm3.768-3.56l-3.415 3.414.707.707 3.415-3.415-.707-.707zM10.086 15a1.5 1.5 0 001.06-.44l-.707-.706a.5.5 0 01-.353.146v1zM14 10.086a.5.5 0 01-.146.353l.707.707a1.5 1.5 0 00.439-1.06h-1zM0 13.5A1.5 1.5 0 001.5 15v-1a.5.5 0 01-.5-.5H0zM13.5 1a.5.5 0 01.5.5h1A1.5 1.5 0 0013.5 0v1zm-12-1A1.5 1.5 0 000 1.5h1a.5.5 0 01.5-.5V0zM11 14.5v-4h-1v4h1zm-.5-3.5h4v-1h-4v1zm3.646-.854l-4 4 .708.708 4-4-.708-.708zM3 4h9V3H3v1z" fill="currentColor"></path>
      </svg>
    """
  end

  def backpack(assigns) do
    ~H"""
    <svg width="20"  version="1.1" id="Icons" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
    viewBox="0 0 144 144" enable-background="new 0 0 144 144" xml:space="preserve" class={classes(assigns)}>
      <path id="XMLID_567_" opacity="0.1" stroke="currentColor"  d="M66,26.26V26v-2c0-4.056,2.7-6,6-6c3.3,0,6,1.79,6,5.8V26v0.259
      c3.352,0.293,6.337,0.841,9,1.625V27v-1c0-10.875-6.75-16-15-16s-15,5-15,16v1v0.888C59.663,27.103,62.648,26.554,66,26.26z"/>
      <path id="XMLID_566_" opacity="0.1" stroke="currentColor"  d="M28.035,118c0.266-3.082,1.389-13.299,2.593-24.03L31,90c-10.875,3-12,10.125-12,17.482
      v4.856c0,5.014,3.965,9.171,9,9.663l0.145-1.543C28.016,119.629,27.966,118.805,28.035,118z"/>
      <path id="XMLID_565_" opacity="0.1" stroke="currentColor"  d="M115.965,118c-0.266-3.082-1.389-13.299-2.593-24.03L113,90c10.875,3,12,10.125,12,17.482
      v4.856c0,5.014-3.965,9.171-9,9.663l-0.145-1.543C115.984,119.629,116.034,118.805,115.965,118z"/>
      <path id="XMLID_564_" opacity="0.1" stroke="currentColor"  d="M72,134h28c2.2,0,4-1.8,4-4l-4-18c-3-16.5-8.833-28-28-28s-25,11.5-28,28l-4,18
      c0,2.2,1.8,4,4,4H72z"/>

      <path id="XMLID_561_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M87,27v-1c0-10.875-6.75-16-15-16s-15,5-15,16v1"/>

      <path id="XMLID_560_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M98,63.75c-2.25-16-5.25-28-26-28s-23.75,12-26,28"/>

      <line id="XMLID_559_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="65" y1="96" x2="79" y2="96"/>

      <path id="XMLID_556_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M31,90c-10.875,3-12,10.125-12,17.482v4.856c0,5.014,3.965,9.171,9,9.663"/>

      <path id="XMLID_555_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M113,90c10.875,3,12,10.125,12,17.482v4.856c0,5.014-3.965,9.171-9,9.663"/>

      <path id="XMLID_553_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M72,134h28c2.2,0,4-1.8,4-4l-4-18c-3-16.5-8.833-28-28-28s-25,11.5-28,28l-4,18c0,2.2,1.8,4,4,4H72z"/>

      <path id="XMLID_552_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M66,26v-2c0-4.056,2.7-6,6-6s6,1.79,6,5.8V26"/>

      <path id="XMLID_550_" fill="none" stroke="currentColor"  stroke-width="4" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="
      M72.015,134h27.952c8.796,0,16.622-8.75,15.997-16c-0.625-7.25-5.993-54-5.993-54c-3.124-22.5-9.112-38-37.974-38h0.018
      c-28.862,0-34.859,15.5-37.983,38c0,0-5.373,46.75-5.997,54c-0.625,7.25,7.197,16,15.993,16H72.015z"/>
    </svg>

    """
  end

  defp classes(assigns) do
    assigns[:class] || ""
  end
end
