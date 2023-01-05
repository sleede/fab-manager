import { act, waitFor } from '@testing-library/react';

interface TipTapEvent {
  type: (element: Element, content: string) => Promise<void>
}

export const tiptapEvent: TipTapEvent = {
  type: async (element, content) => {
    await act(async () => {
      element.innerHTML = content;
      await waitFor(() => {
        expect(element.innerHTML).toBe(content);
      });
    });
  }
};
