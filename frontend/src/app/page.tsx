"use client";

import { useState, useEffect } from 'react';

// Define the type for a single todo item
interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

export default function Home() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTodoTitle, setNewTodoTitle] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch todos from the backend on component mount
  useEffect(() => {
    const fetchTodos = async () => {
      try {
        const response = await fetch(`${API_URL}/todos`);
        if (!response.ok) {
          throw new Error('Failed to fetch todos');
        }
        const data: Todo[] = await response.json();
        setTodos(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch todos');
      } finally {
        setLoading(false);
      }
    };
    fetchTodos();
  }, []);

  // Handle form submission to add a new todo
  const handleAddTodo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTodoTitle.trim()) return;

    try {
      const response = await fetch(`${API_URL}/todos`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: newTodoTitle }),
      });
      if (!response.ok) {
        throw new Error('Failed to add todo');
      }
      const newTodo = await response.json();
      setTodos([...todos, newTodo]);
      setNewTodoTitle('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add todo');
    }
  };

  // Handle toggling the completed status of a todo
  const handleToggleComplete = async (id: number, completed: boolean) => {
    try {
      const response = await fetch(`${API_URL}/todos/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ completed: !completed }),
      });
      if (!response.ok) {
        throw new Error('Failed to update todo');
      }
      const updatedTodo = await response.json();
      setTodos(todos.map(todo => todo.id === id ? updatedTodo : todo));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update todo');
    }
  };

  // Handle deleting a todo
  const handleDeleteTodo = async (id: number) => {
    try {
      const response = await fetch(`${API_URL}/todos/${id}`, { method: 'DELETE' });
      if (!response.ok) {
        throw new Error('Failed to delete todo');
      }
      setTodos(todos.filter(todo => todo.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete todo');
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center p-24 bg-gray-900 text-white">
      <div className="z-10 w-full max-w-2xl items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold mb-8 text-center">Todo List</h1>

        {error && <p className="text-red-500 bg-red-100 p-3 rounded mb-4">Error: {error}</p>}

        <form onSubmit={handleAddTodo} className="flex gap-4 mb-8">
          <input
            type="text"
            value={newTodoTitle}
            onChange={(e) => setNewTodoTitle(e.target.value)}
            placeholder="What needs to be done?"
            className="flex-grow p-3 rounded bg-gray-800 border border-gray-700 focus:ring-2 focus:ring-blue-500 focus:outline-none"
          />
          <button
            type="submit"
            className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded transition-colors"
          >
            Add
          </button>
        </form>

        {loading ? (
          <p>Loading...</p>
        ) : (
          <ul className="space-y-4 w-full">
            {todos.map((todo) => (
              <li
                key={todo.id}
                className={`flex items-center justify-between p-4 rounded-lg transition-colors ${todo.completed ? 'bg-green-900/50 text-gray-500' : 'bg-gray-800'
                  }`}
              >
                <span
                  className={`cursor-pointer ${todo.completed ? 'line-through' : ''}`}
                  onClick={() => handleToggleComplete(todo.id, todo.completed)}
                >
                  {todo.title}
                </span>
                <button
                  onClick={() => handleDeleteTodo(todo.id)}
                  className="bg-red-600 hover:bg-red-700 text-white font-bold py-1 px-3 rounded text-sm transition-colors"
                >
                  Delete
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </main>
  );
}
